//
//  InviteCreateUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 3/29/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public struct InviteCreateUseCase: UseCase {
    public var groupId: GroupID
    public var lifetimeDuration: Timestamp?
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        groupId: GroupID,
        lifetimeDuration: Timestamp? = nil,
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.groupId = groupId
        self.lifetimeDuration = lifetimeDuration
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        let (session, userKey, currentEpoch, metadataEpoch) = try await dataStore.read { db in
            let session = try SessionModel.fetchExpect(db)
            let userKey = try UserKeyModel.fetchExpect(db, id: session.userId)
            let currentEpoch = try EpochModel.fetchCurrent(db, groupId: groupId)
            let metadataEpoch = try MetadataModel.fetchEpoch(db, id: groupId)
            return (session, userKey, currentEpoch, metadataEpoch)
        }

        let recoveryKey: SymmetricKey = try keychainStorage.get(.recoveryKey(session.userId))

        let signingKey: Curve25519.Signing.PrivateKey = try keychainStorage.get(
            .userSigningKey(userKey.id)
        )

        let secretKey = SymmetricKey(size: .bits256)

        let timestamp = Timestamp.now()
        let virtualId = VirtualMemberID()

        let invite = InvitePayload(
            token: Data(randomBytes: 32),
            groupId: groupId,
            ownerUserId: session.userId,
            virtualId: virtualId,
            timestamp: timestamp,
            lifetime: lifetimeDuration
        )

        let storeKey = Curve25519.KeyAgreement.PrivateKey()
        let storeKeyKyber = try Kyber1024.pair()

        let virtualSecrets = VirtualMemberPayload.Secrets(
            epochRootKey: try keychainStorage.get(
                .epochRootKey(currentEpoch.id)
            ),
            metadataEpochRootKey: try keychainStorage.get(
                .epochRootKey(metadataEpoch.id)
            ),
            storeKey: storeKey,
            storeKeyKyber: storeKeyKyber.privateKey
        )

        let virtualMember = try VirtualMemberPayload(
            groupId: groupId,
            virtualId: virtualId,
            ownerUserId: session.userId,
            epochId: currentEpoch.id,
            metadataEpochId: metadataEpoch.id,
            storeKey: storeKey.publicKey,
            storeKeyKyber: storeKeyKyber.publicKey,
            secrets: try virtualSecrets.encrypt(virtualId: virtualId, secretKey: secretKey),
            timestamp: timestamp,
            signingKey: signingKey
        )

        let secret = try secretKey.withUnsafeBytes { bytes in
            try SecretPayload(
                secretType: .inviteSecretKey,
                objectId: virtualId,
                encrypting: bytes,
                usingRecoveryKey: recoveryKey,
                timestamp: timestamp
            )
        }

        let payload = InviteCreatePayload(
            invite: invite,
            virtualMember: virtualMember,
            secret: secret
        )

        let pendingEvent = try PendingEvent(eventType: .inviteCreate, payload: payload)

        try keychainStorage.save(secretKey, to: .inviteSecretKey(invite.virtualId))

        try await dataStore.write { db in
            try InviteModel(payload: payload.invite, isPending: true).save(db)
            try VirtualMemberModel(payload: virtualMember).save(db)
            try pendingEvent.save(db)
        }

        _ = try await pendingEvent.result()
    }
}

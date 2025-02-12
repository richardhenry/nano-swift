//
//  GroupCreateUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 3/29/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public struct GroupCreateUseCase: UseCase {
    public var groupId: GroupID?
    public var name: String
    public var image: LocalAttachment?
    public var emoji: String?
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        groupId: GroupID? = nil,
        name: String,
        image: LocalAttachment?,
        emoji: String?,
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.groupId = groupId
        self.name = name
        self.image = image
        self.emoji = emoji
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        let groupId = groupId ?? GroupID()
        let name = name.trimmingCharacters(in: .whitespaces)

        guard !name.isEmpty else {
            throw error("Group name must not be empty.")
        }

        let (session, userKey) = try await dataStore.read { db in
            let session = try SessionModel.fetchExpect(db)
            let userKey = try UserKeyModel.fetchExpect(db, id: session.userId)
            return (session, userKey)
        }

        let recoveryKey: SymmetricKey = try keychainStorage.get(.recoveryKey(session.userId))

        let signingKey: Curve25519.Signing.PrivateKey =
            try keychainStorage
            .get(.userSigningKey(userKey.id))

        let timestamp = Timestamp.now()

        let group = GroupModel(id: groupId, name: name)

        let groupPayload = GroupPayload(
            groupId: group.id,
            timestamp: timestamp
        )

        let storeKey = Curve25519.KeyAgreement.PrivateKey()
        let storeKeyKyber = try Kyber1024.pair()
        let authKey = Curve25519.KeyAgreement.PrivateKey()

        let member = MemberModel(
            groupId: group.id,
            userId: session.userId,
            storeKey: storeKey.publicKey,
            storeKeyKyber: storeKeyKyber.publicKey,
            authKey: authKey.publicKey,
            timestamp: timestamp
        )

        let memberPayload = try MemberPayload(
            member: member,
            signingKey: signingKey
        )

        let epoch = EpochModel(
            groupId: group.id,
            id: EpochID(),
            sequenceId: 0,
            isDiscontiguous: false,
            timestamp: timestamp
        )

        let epochRootKey = SymmetricKey(size: .bits256)
        try keychainStorage.save(epochRootKey, to: .epochRootKey(epoch.id))

        try keychainStorage.save(storeKey, to: .memberStoreKey(session.userId, group.id))
        try keychainStorage.save(
            storeKeyKyber.privateKey,
            to: .memberStoreKeyKyber(session.userId, group.id)
        )
        try keychainStorage.save(authKey, to: .memberAuthKey(session.userId, group.id))

        let epochPayload = try EpochPayload(
            groupId: epoch.groupId,
            epochId: epoch.id,
            sequenceId: epoch.sequenceId,
            creatorUserId: session.userId,
            previousEpoch: nil,
            timestamp: epoch.timestamp,
            signingKey: signingKey
        )

        let encryptedImage = try await GroupEditUseCase.prepareImage(image: image)

        let content = MetadataPayload.Content(
            name: name,
            image: encryptedImage,
            emoji: emoji
        )

        let metadata = try MetadataPayload(
            groupId: group.id,
            encrypting: content,
            inEpoch: epoch,
            epochRootKey: epochRootKey,
            userId: session.userId,
            signingKey: signingKey
        )

        let secret = try SecretPayload(
            secretType: .memberKey,
            objectId: member.groupId,
            encrypting: try SecretSaveUseCase.memberKeyBundle(
                storeKey: storeKey,
                storeKeyKyber: storeKeyKyber.privateKey,
                authKey: authKey
            ),
            usingRecoveryKey: recoveryKey,
            timestamp: timestamp
        )

        let recovery = try MemberRecoveryPayload(
            groupId: groupId,
            userId: session.userId,
            epochId: epoch.id,
            metadataEpochId: epoch.id,
            encrypting: .init(
                epochRootKey: epochRootKey,
                metadataEpochRootKey: epochRootKey
            ),
            recoveryKey: recoveryKey,
            senderSessionId: session.sessionId,
            timestamp: timestamp
        )

        let macKey = EpochDeriveUseCase.deriveMacKey(
            epochId: epoch.id,
            rootKey: epochRootKey
        )

        let mac = EpochDeriveUseCase.generateMac(
            macKey: macKey,
            publicSigningKey: userKey.signing
        )

        let groupCreate = GroupCreatePayload(
            group: groupPayload,
            member: memberPayload,
            epoch: epochPayload,
            metadata: metadata,
            secret: secret,
            recovery: recovery,
            mac: mac
        )

        let pendingCreate = try PendingEvent(
            eventType: .groupCreate,
            payload: groupCreate
        )

        try await dataStore.write { db in
            try group.insert(db)
            try MetadataModel(id: group.id, epochId: epoch.id).save(db)
            try epoch.save(db)
            try pendingCreate.save(db)
        }

        _ = try await pendingCreate.result(expect: .memberRecord)
    }
}

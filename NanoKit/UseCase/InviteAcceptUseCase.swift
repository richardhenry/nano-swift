//
//  InviteAcceptUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 3/29/24.
//

import Combine
import CryptoKit
import Foundation
import MessagePack
import NanoCore
import NanoCrypto
import OrderedCollections

public struct InviteAcceptUseCase: UseCase {
    public var token: Data
    public var secretKey: SymmetricKey
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        token: Data,
        secretKey: SymmetricKey,
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.token = token
        self.secretKey = secretKey
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        let pendingRequest = try PendingEvent(
            eventType: .inviteGet,
            payload: InviteGetPayload(token: token)
        )

        try await dataStore.write { db in try pendingRequest.save(db) }

        let payload = try await pendingRequest.result(expect: .inviteBundle)
            .payload(as: InviteBundlePayload.self)

        try await handle(inviteBundle: payload)
    }

    public func handle(inviteBundle payload: InviteBundlePayload) async throws {
        guard payload.existingMember?.state != .live else {
            log(
                .info,
                "Viewer is already in this group, doing nothing. Group ID: \(payload.group.groupId)"
            )
            return
        }

        guard payload.invite.token == token else {
            throw error("Invite bundle does not match.")
        }

        let groupId = payload.group.groupId

        let (session, userKey, virtualSigningKey) = try await dataStore.read { db in
            let session = try SessionModel.fetchExpect(db)
            let userKey = try UserKeyModel.fetchExpect(db, id: session.userId)
            let virtualSigningKey = try payload.virtualMember.fetchSigningKey(db)
            return (session, userKey, virtualSigningKey)
        }

        let recoveryKey: SymmetricKey = try keychainStorage.get(.recoveryKey(session.userId))
        let signingKey: Curve25519.Signing.PrivateKey = try keychainStorage.get(
            .userSigningKey(userKey.id)
        )

        if let secret = payload.secret {
            try await SecretSaveUseCase(
                userId: session.userId,
                secret: secret,
                dataStore: dataStore,
                keychainStorage: keychainStorage
            )
            .run()
        }

        try payload.virtualMember.validateSignature(with: virtualSigningKey)

        let storeKey: Curve25519.KeyAgreement.PrivateKey
        let storeKeyKyber: Kyber1024.Pair
        let authKey: Curve25519.KeyAgreement.PrivateKey

        if let existing = payload.existingMember {
            // If the viewer was previously in the group, we must use the existing keys.

            try existing.validateSignature(with: userKey)

            storeKey = try keychainStorage.get(.memberStoreKey(session.userId, groupId))
            authKey = try keychainStorage.get(.memberAuthKey(session.userId, groupId))

            // Sanity check.
            guard storeKey.publicKey == existing.storeKey,
                authKey.publicKey == existing.authKey
            else {
                throw error("Existing Curve25519 private keys do not match.")
            }

            storeKeyKyber = Kyber1024.Pair(
                privateKey: try keychainStorage.get(.memberStoreKeyKyber(session.userId, groupId)),
                publicKey: existing.storeKeyKyber
            )
        } else {
            storeKey = .init()
            storeKeyKyber = try Kyber1024.pair()
            authKey = .init()

            try keychainStorage.save(storeKey, to: .memberStoreKey(session.userId, groupId))
            try keychainStorage.save(
                storeKeyKyber.privateKey,
                to: .memberStoreKeyKyber(session.userId, groupId)
            )
            try keychainStorage.save(authKey, to: .memberAuthKey(session.userId, groupId))
        }

        let timestamp = Timestamp.now()

        let member = MemberModel(
            groupId: payload.group.groupId,
            userId: session.userId,
            storeKey: storeKey.publicKey,
            storeKeyKyber: storeKeyKyber.publicKey,
            authKey: authKey.publicKey,
            timestamp: timestamp
        )

        let virtualSecrets = try payload.virtualMember.decryptSecrets(secretKey: secretKey)

        var rootKeys = [payload.virtualMember.metadataEpochId: virtualSecrets.metadataEpochRootKey]
        rootKeys[payload.virtualMember.epochId] = virtualSecrets.epochRootKey

        let (group, metadata, epochs) = try await GroupBootstrapUseCase(
            group: payload.group,
            // Group is pending because we need to wait for the server to return the new member record.
            groupIsPending: true,
            member: member,
            metadata: payload.metadata,
            bundles: payload.epochs,
            rootKeys: rootKeys,
            storeKey: virtualSecrets.storeKey,
            storeKeyKyber: virtualSecrets.storeKeyKyber,
            dataStore: dataStore,
            keychainStorage: keychainStorage
        )
        .run()

        let memberPayload = try MemberPayload(member: member, signingKey: signingKey)

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

        let lastEpochId = epochs.last!.id

        let lastEpochRootKey: SymmetricKey = try keychainStorage.get(
            .epochRootKey(lastEpochId)
        )

        let recovery = try MemberRecoveryPayload(
            groupId: group.id,
            userId: session.userId,
            epochId: lastEpochId,
            metadataEpochId: metadata.epochId,
            encrypting: .init(
                epochRootKey: lastEpochRootKey,
                metadataEpochRootKey: try keychainStorage.get(
                    .epochRootKey(metadata.epochId)
                )
            ),
            recoveryKey: recoveryKey,
            senderSessionId: session.sessionId,
            timestamp: timestamp
        )

        let macKey = EpochDeriveUseCase.deriveMacKey(
            epochId: lastEpochId,
            rootKey: lastEpochRootKey
        )

        let mac = EpochDeriveUseCase.generateMac(
            macKey: macKey,
            publicSigningKey: userKey.signing
        )

        let accept = InviteAcceptPayload(
            token: token,
            member: memberPayload,
            secret: secret,
            recovery: recovery,
            epochId: lastEpochId,
            mac: mac
        )

        let pendingAccept = try PendingEvent(eventType: .inviteAccept, payload: accept)

        try await dataStore.write { db in
            try group.insert(db, onConflict: .ignore)
            try metadata.save(db)
            try epochs.forEach { try $0.save(db) }
            try pendingAccept.save(db)
        }

        _ = try await pendingAccept.result(expect: .memberRecord)
    }
}

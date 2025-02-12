//
//  EpochCreateUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 3/30/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public struct EpochCreateUseCase: UseCase {
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(dataStore: DataStore = .shared, keychainStorage: KeychainStorage = .shared) {
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        let epochs = try await dataStore.read { db in
            try EpochDirtyModel.fetchDirty(db)
                .compactMap {
                    if try RoleModel.hasPermission(
                        db,
                        id: $0.id,
                        adminPermission: .memberBanAndEpochCreate
                    ) {
                        return try EpochModel.fetchCurrent(db, groupId: $0.id)
                    } else {
                        log(.debug, "Ignoring dirty epoch, not an admin: \($0.id)")
                        return nil
                    }
                }
        }

        log(.debug, "Dirty epochs: \(epochs)")

        for epoch in epochs {
            try await createNext(from: epoch)
        }
    }

    func createNext(from previousEpoch: EpochModel) async throws {
        log(.debug, "Creating next epoch from previous epoch: \(previousEpoch)")

        guard previousEpoch.sequenceId < UInt32.max else {
            throw error("Saturated sequence ID.")
        }

        let session = try await dataStore.read { db in
            try SessionModel.fetchExpect(db)
        }

        let previousRootKey: SymmetricKey = try keychainStorage.get(
            .epochRootKey(previousEpoch.id)
        )

        let signingKey: Curve25519.Signing.PrivateKey = try keychainStorage.get(
            .userSigningKey(session.userId)
        )

        let authKey: Curve25519.KeyAgreement.PrivateKey = try keychainStorage.get(
            .memberAuthKey(session.userId, previousEpoch.groupId)
        )

        let epochId = EpochID()

        let (chainingKey, preSharedKey) = EpochDeriveUseCase.deriveChainingKeys(
            previousRootKey: previousRootKey,
            nextEpochId: epochId
        )

        let newEntropy = SymmetricKey(size: .bits256)

        let rootKey = EpochDeriveUseCase.deriveNextRootKey(
            newEntropy: newEntropy,
            chainingKey: chainingKey
        )

        let epoch = try EpochPayload(
            groupId: previousEpoch.groupId,
            epochId: epochId,
            sequenceId: previousEpoch.sequenceId + 1,
            creatorUserId: session.userId,
            previousEpoch: try .init(
                previousEpochId: previousEpoch.id,
                encryptingPrevRootKey: previousRootKey,
                fromNextRootKey: rootKey
            ),
            timestamp: .now(),
            signingKey: signingKey
        )

        let (members, virtualMembers, previousMacs) = try await dataStore.read { db in
            let members = try MemberModel.fetchAll(db, groupId: previousEpoch.groupId, state: .live)
            let virtualMembers = try VirtualMemberModel.fetchAll(db, groupId: previousEpoch.groupId)

            let previousMacs = try EpochMacBulkQuery(
                groupId: previousEpoch.groupId,
                epochId: previousEpoch.id
            )
            .fetch(db)

            return (members, virtualMembers, previousMacs)
        }

        let previousMacKey = EpochDeriveUseCase.deriveMacKey(
            epochId: previousEpoch.id,
            rootKey: previousRootKey
        )

        let macKey = EpochDeriveUseCase.deriveMacKey(
            epochId: epochId,
            rootKey: rootKey
        )

        var payload = EpochCreatePayload(epoch: epoch)

        for member in members {
            guard let (previousMac, userKey) = previousMacs[member.userId] else {
                throw error(
                    "Missing MAC for member. Group ID: \(member.groupId) User ID: \(member.userId)"
                )
            }

            guard let userKey else {
                throw error("Missing public signing key for user. User ID: \(member.userId)")
            }

            let expectedMac = EpochDeriveUseCase.generateMac(
                macKey: previousMacKey,
                publicSigningKey: userKey.signing
            )

            guard expectedMac == previousMac.mac else {
                log(
                    .warning,
                    "MAC for member does not match. Group ID: \(member.groupId) User ID: \(member.userId)"
                )
                payload.invalidUserIds.append(member.userId)
                continue
            }

            let secrets = try newEntropy.withUnsafeBytes { newEntropyBytes in
                try LabyrinthPQHPKE.seal(
                    recipientKey: member.storeKey,
                    recipientKeyKyber: member.storeKeyKyber,
                    senderKey: authKey,
                    preSharedKey: preSharedKey,
                    message: newEntropyBytes,
                    authenticating: Data("epoch_\(epoch.epochId.base64EncodedString)".utf8)
                )
            }

            let entropy = EntropyPayload(
                recipientType: .member,
                recipientId: member.userId.eraseToAny(),
                ciphertext: secrets
            )

            let mac = EpochMacPartialPayload(
                userId: member.userId,
                mac: EpochDeriveUseCase.generateMac(
                    macKey: macKey,
                    publicSigningKey: userKey.signing
                )
            )

            payload.entropy.append(entropy)
            payload.macs.append(mac)
        }

        for virtualMember in virtualMembers {
            guard previousMacs.keys.contains(virtualMember.ownerUserId) else {
                log(
                    .warning,
                    "Virtual member does not have a MAC. Group ID: \(virtualMember.groupId) Virtual ID: \(virtualMember.virtualId)"
                )
                payload.invalidUserIds.append(virtualMember.ownerUserId)
                continue
            }

            let secrets = try newEntropy.withUnsafeBytes { newEntropyBytes in
                try LabyrinthPQHPKE.seal(
                    recipientKey: virtualMember.storeKey,
                    recipientKeyKyber: virtualMember.storeKeyKyber,
                    senderKey: authKey,
                    preSharedKey: preSharedKey,
                    message: newEntropyBytes,
                    authenticating: Data("epoch_\(epoch.epochId.base64EncodedString)".utf8)
                )
            }

            let entropy = EntropyPayload(
                recipientType: .virtualMember,
                recipientId: virtualMember.virtualId.eraseToAny(),
                ciphertext: secrets
            )

            payload.entropy.append(entropy)
        }

        log(
            .debug,
            "Distributing epoch to \(members.count) members and \(virtualMembers.count) virtual members: \(payload.epoch)"
        )

        let finalPayload = payload
        try await dataStore.write { db in
            // Rather than immediately saving this epoch and starting to encrypt new messages into it, we will wait for the server to return the epoch back to us. That way we know that it's distributed correctly and we won't break anything.
            try PendingEvent(eventType: .epochCreate, payload: finalPayload).save(db)

            // Save the epoch timestamp in the dirty model so that we don't derive another one immediately.
            try EpochDirtyModel.set(db, id: epoch.groupId, lastEpochTimestamp: epoch.timestamp)
        }
    }
}

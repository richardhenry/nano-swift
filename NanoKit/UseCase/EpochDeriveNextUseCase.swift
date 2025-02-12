//
//  EpochDeriveNextUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 3/30/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public struct EpochDeriveNextUseCase: UseCase {
    public var bundle: EpochBundlePayload
    public var member: MemberModel?
    public var dataStore: DataStore = .shared
    public var keychainStorage: KeychainStorage = .shared

    public func run() async throws {
        guard bundle.ciphertext != nil else {
            throw error("Missing secrets in bundle: \(bundle)")
        }

        guard let previousEpoch = bundle.epoch.previousEpoch else {
            throw error("Missing previous epoch in bundle: \(bundle)")
        }

        let (session, exists, prevEpoch, userKey) = try await dataStore.read { db in
            let session = try SessionModel.fetchExpect(db)
            let exists =
                try EpochModel.fetchOne(
                    db,
                    groupId: bundle.epoch.groupId,
                    id: bundle.epoch.epochId
                ) != nil
            let prevEpoch = try EpochModel.fetchExpect(
                db,
                groupId: bundle.epoch.groupId,
                id: previousEpoch.epochId
            )
            let userKey = try UserKeyModel.fetchExpect(db, id: bundle.epoch.creatorUserId)
            return (session, exists, prevEpoch, userKey)
        }

        guard !exists else {
            log(.info, "Epoch already exists: \(bundle.epoch)")
            return
        }

        try bundle.epoch.validateSignature(with: userKey)

        let storeKey: Curve25519.KeyAgreement.PrivateKey = try keychainStorage.get(
            .memberStoreKey(session.userId, bundle.epoch.groupId)
        )

        let storeKeyKyber: Kyber1024.PrivateKey = try keychainStorage.get(
            .memberStoreKeyKyber(session.userId, bundle.epoch.groupId)
        )

        let newEpoch = try await deriveNext(
            previousEpoch: prevEpoch,
            storeKey: storeKey,
            storeKeyKyber: storeKeyKyber
        )

        try await dataStore.write { db in
            try newEpoch.save(db)
        }

        log(.info, "Derived next epoch: \(newEpoch)")
    }

    func deriveNext(
        previousEpoch: EpochModel,
        storeKey: Curve25519.KeyAgreement.PrivateKey,
        storeKeyKyber: Kyber1024.PrivateKey
    ) async throws -> EpochModel {
        guard let previousEpochId = bundle.epoch.previousEpoch?.epochId else {
            throw error("Epoch in bundle does not reference a previous epoch: \(bundle)")
        }

        guard previousEpochId == previousEpoch.id else {
            throw error(
                "Previous epoch doesn't match bundle: \(bundle) Previous epoch: \(previousEpoch)"
            )
        }

        guard let secrets = bundle.ciphertext else {
            throw error("Missing secrets in bundle: \(bundle)")
        }

        let prevRootKey: SymmetricKey = try keychainStorage.get(
            .epochRootKey(previousEpoch.id)
        )

        let (chainingKey, preSharedKey) = EpochDeriveUseCase.deriveChainingKeys(
            previousRootKey: prevRootKey,
            nextEpochId: bundle.epoch.epochId
        )

        let senderAuthKey: Curve25519.KeyAgreement.PublicKey

        if let member,
            member.groupId == bundle.epoch.groupId,
            member.userId == bundle.epoch.creatorUserId
        {
            senderAuthKey = member.authKey
        } else {
            senderAuthKey = try await dataStore.read { db in
                try MemberModel.fetchExpect(
                    db,
                    groupId: bundle.epoch.groupId,
                    userId: bundle.epoch.creatorUserId,
                    state: [.live, .historic]
                )
                .authKey
            }
        }

        let newEntropy =
            try LabyrinthPQHPKE.open(
                secrets,
                recipientKey: storeKey,
                recipientKeyKyber: storeKeyKyber,
                senderKey: senderAuthKey,
                preSharedKey: preSharedKey,
                authenticating: Data("epoch_\(bundle.epoch.epochId.base64EncodedString)".utf8),
                intoSecureMemory: true
            )
            .withUnsafeBytes { SymmetricKey(data: $0) }

        let rootKey = EpochDeriveUseCase.deriveNextRootKey(
            newEntropy: newEntropy,
            chainingKey: chainingKey
        )

        // Sanity check.
        _ = try bundle.epoch.previousEpoch?.decryptRootKey(nextRootKey: rootKey)

        try keychainStorage.save(rootKey, to: .epochRootKey(bundle.epoch.epochId))

        return EpochModel(
            payload: bundle.epoch,
            isDiscontiguous: false
        )
    }
}

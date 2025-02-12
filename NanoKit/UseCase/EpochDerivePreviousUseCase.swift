//
//  EpochDerivePreviousUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 3/30/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public struct EpochDerivePreviousUseCase: UseCase {
    public var epoch: EpochPayload
    public var dataStore: DataStore = .shared
    public var keychainStorage: KeychainStorage = .shared

    public func run() async throws {
        let (existing, userKey) = try await dataStore.read { db in
            let existing = try EpochModel.fetchOne(db, groupId: epoch.groupId, id: epoch.epochId)
            let userKey = try UserKeyModel.fetchExpect(db, id: epoch.creatorUserId)
            return (existing, userKey)
        }

        try epoch.validateSignature(with: userKey)

        if existing == nil {
            let rootKey: SymmetricKey = try keychainStorage.get(
                .epochRootKey(epoch.epochId)
            )

            if let previousEpoch = epoch.previousEpoch {
                let prevRootKey = try previousEpoch.decryptRootKey(nextRootKey: rootKey)
                try keychainStorage.save(
                    prevRootKey,
                    to: .epochRootKey(previousEpoch.epochId)
                )
            }

            let newEpoch = EpochModel(
                payload: epoch,
                isDiscontiguous: false
            )

            try await dataStore.write { db in
                try newEpoch.save(db)
            }

            log(.info, "Derived previous epoch: \(newEpoch)")

        } else if existing?.isDiscontiguous == true {
            try await dataStore.write { db in
                try EpochModel.markContiguous(db, groupId: epoch.groupId, id: epoch.epochId)
            }
        }
    }
}

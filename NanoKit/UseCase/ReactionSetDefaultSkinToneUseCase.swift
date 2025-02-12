//
//  ReactionSetDefaultSkinToneUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/7/24.
//

import CryptoKit
import Foundation
import NanoCrypto

public struct ReactionSetDefaultSkinToneUseCase: UseCase {
    public var skinToneVariation: Int?
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        skinToneVariation: Int?,
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.skinToneVariation = skinToneVariation
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        let session = try await dataStore.read { db in
            try SessionModel.fetchExpect(db)
        }

        let recoveryKey: SymmetricKey = try keychainStorage.get(.recoveryKey(session.userId))

        let settingPayload = try SecretSettingPayload(
            userId: session.userId,
            settingType: .reactionSkinTone,
            encrypting: skinToneVariation,
            usingRecoveryKey: recoveryKey,
            timestamp: .now()
        )

        let pendingEvent = try PendingEvent(
            eventType: .secretSettingUpdate,
            payload: settingPayload
        )

        try await dataStore.write { db in
            try SecretSettingModel(
                settingType: .reactionSkinTone,
                isOptimistic: true,
                value: skinToneVariation
            )
            .save(db)
            try pendingEvent.save(db)
        }
    }
}

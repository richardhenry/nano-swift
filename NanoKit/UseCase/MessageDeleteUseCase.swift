//
//  MessageDeleteUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 5/16/24.
//

import CryptoKit
import Foundation
import NanoCrypto

public struct MessageDeleteUseCase: UseCase {
    public var message: MessageModel
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        message: MessageModel,
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.message = message
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        let session = try await dataStore.read { db in
            try SessionModel.fetchExpect(db)
        }

        let signingKey: Curve25519.Signing.PrivateKey = try keychainStorage.get(
            .userSigningKey(session.userId)
        )

        let payload = try MessageDeletePayload(
            deleting: .message(message),
            deletedByUserId: session.userId,
            signingKey: signingKey
        )

        let pendingEvent = try PendingEvent(
            eventType: .messageDelete,
            payload: payload
        )

        try await dataStore.write { db in
            try pendingEvent.save(db)
        }
    }
}

//
//  MessageSendDeferredUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/8/24.
//

import CryptoKit
import Foundation
import NanoCrypto

public struct MessageSendDeferredUseCase: UseCase {
    public var groupId: GroupID
    public var messageId: MessageID
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        groupId: GroupID,
        messageId: MessageID,
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.groupId = groupId
        self.messageId = messageId
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        let (session, message, epoch) = try await dataStore.read { db in
            let session = try SessionModel.fetchExpect(db)
            let message = try MessageModel.fetchExpect(db, groupId: groupId, id: messageId)
            let epoch = try EpochModel.fetchCurrent(db, groupId: message.groupId)
            return (session, message, epoch)
        }

        let signingKey: Curve25519.Signing.PrivateKey = try keychainStorage.get(
            .userSigningKey(session.userId)
        )

        let messagePayload = try MessageUpdatePayload(
            encrypting: .message(message),
            inEpoch: epoch,
            senderUserId: session.userId,
            signingKey: signingKey
        )

        let messageEvent = try PendingEvent(
            eventType: message.editTimestamp != nil ? .messageUpdate : .messageCreate,
            payload: messagePayload
        )

        try await dataStore.write { db in
            try MessageModel.setSendState(
                db,
                groupId: groupId,
                id: messageId,
                newValue: .pending
            )

            try messageEvent.save(db)

            try db.execute(
                sql: """
                        DELETE FROM pending_attachment
                        WHERE attachment_group_id = ?
                            AND attachment_message_id = ?
                    """,
                arguments: [groupId, messageId]
            )
        }
    }
}

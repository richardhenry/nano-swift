//
//  MessageSendRetryUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/8/24.
//

import CryptoKit
import Foundation
import NanoCrypto

public struct MessageSendRetryUseCase: UseCase {
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
        let incompleteAttachments = try await dataStore.read { db in
            try PendingAttachment.fetchIncomplete(db, groupId: groupId, messageId: messageId)
        }

        if !incompleteAttachments.isEmpty {
            try await dataStore.write { db in
                try MessageModel.setSendState(
                    db,
                    groupId: groupId,
                    id: messageId,
                    newValue: .waitingForAttachments
                )
            }

            for attachment in incompleteAttachments {
                PendingAttachmentUseCase(
                    pendingAttachment: attachment,
                    dataStore: dataStore,
                    keychainStorage: keychainStorage
                )
                .detachedTask()
            }
        } else {
            try await MessageSendDeferredUseCase(
                groupId: groupId,
                messageId: messageId,
                dataStore: dataStore,
                keychainStorage: keychainStorage
            )
            .run()
        }
    }
}

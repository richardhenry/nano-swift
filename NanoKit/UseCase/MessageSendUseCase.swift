//
//  MessageSendUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/8/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public struct MessageSendUseCase: UseCase {
    public var groupId: GroupID
    public var messageId: MessageID
    public var threadId: ThreadID
    public var isRoot: Bool
    public var text: String
    public var attachmentPicker: AttachmentPicker
    public var links: [LinkProvider]
    public var mentions: [Mention]
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        groupId: GroupID,
        messageId: MessageID,
        threadId: ThreadID,
        isRoot: Bool,
        text: String,
        attachmentPicker: AttachmentPicker,
        links: [LinkProvider],
        mentions: [Mention],
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.groupId = groupId
        self.messageId = messageId
        self.threadId = threadId
        self.isRoot = isRoot
        self.text = text
        self.attachmentPicker = attachmentPicker
        self.links = links
        self.mentions = mentions
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        let (attachments, linkPreviews, pendingAttachments) = try await MessageAttachmentUseCase(
            groupId: groupId,
            messageId: messageId,
            attachmentPicker: attachmentPicker,
            links: links
        )
        .run()

        guard !text.isEmpty || !attachments.isEmpty || !linkPreviews.isEmpty else {
            throw error("Message is empty.")
        }

        let (session, epoch, existing, starOnReply, visibility) = try await dataStore.read { db in
            let session = try SessionModel.fetchExpect(db)
            let epoch = try EpochModel.fetchCurrent(db, groupId: groupId)

            let existing = try MessageModel.fetchOne(db, groupId: groupId, id: messageId)

            let starOnReply: Bool = try GroupSettingModel.fetchValue(
                db,
                groupId: groupId,
                settingType: .starOnReply,
                defaultValue: true
            )

            let visibility: ThreadVisibilityValue? = try ThreadSettingModel.fetchValue(
                db,
                groupId: groupId,
                threadId: threadId,
                settingType: .visibility
            )

            return (session, epoch, existing, starOnReply, visibility)
        }

        let signingKey: Curve25519.Signing.PrivateKey = try keychainStorage.get(
            .userSigningKey(session.userId)
        )

        let message = MessageModel(
            groupId: groupId,
            id: messageId,
            threadId: threadId,
            userId: session.userId,
            deletedByUserId: nil,
            isRoot: isRoot,
            text: text.nonEmptyOrNil(),
            attachments: attachments.nonEmptyOrNil(),
            links: linkPreviews.nonEmptyOrNil(),
            mentions: mentions.nonEmptyOrNil(),
            sendState: pendingAttachments.isEmpty ? .pending : .waitingForAttachments,
            createTimestamp: existing?.createTimestamp ?? .now(),
            editTimestamp: existing == nil ? nil : .now()
        )

        let messageEvent: PendingEvent?

        if pendingAttachments.isEmpty {
            let messagePayload = try MessageUpdatePayload(
                encrypting: .message(message),
                inEpoch: epoch,
                senderUserId: session.userId,
                signingKey: signingKey
            )

            messageEvent = try PendingEvent(
                eventType: existing == nil ? .messageCreate : .messageUpdate,
                payload: messagePayload
            )
        } else {
            // The message payload will be sent once the attachments have finished uploading.
            messageEvent = nil
        }

        let starEvent: PendingEvent?

        if visibility == nil, starOnReply, existing == nil {
            let settingPayload = ThreadSettingPayload(
                userId: session.userId,
                groupId: groupId,
                threadId: threadId,
                settingType: .visibility,
                value: ThreadVisibilityValue.starred,
                timestamp: .now()
            )

            starEvent = try PendingEvent(
                eventType: .threadSettingUpdate,
                payload: settingPayload
            )
        } else {
            starEvent = nil
        }

        try await dataStore.write { [pendingAttachments] db in
            try message.save(db)

            if existing == nil {
                try ThreadModel.upsert(db, fromMessage: message)
            }

            try messageEvent?.save(db)

            for pendingAttachment in pendingAttachments {
                try pendingAttachment.save(db)
            }

            if let starEvent = starEvent {
                try ThreadSettingModel(
                    groupId: groupId,
                    threadId: threadId,
                    settingType: .visibility,
                    optimisticValue: ThreadVisibilityValue.starred
                )
                .save(db)
                try starEvent.save(db)
            }
        }

        for pendingAttachment in pendingAttachments {
            PendingAttachmentUseCase(
                pendingAttachment: pendingAttachment,
                dataStore: dataStore,
                keychainStorage: keychainStorage
            )
            .detachedTask()
        }
    }
}

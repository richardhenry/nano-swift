//
//  MessageModel.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

import Combine
import Foundation
import GRDB
import NanoCore

public struct MessageModel: Equatable, Codable, FetchableRecord, PersistableRecord {
    public enum SendState: Int, Codable, DatabaseValueConvertible {
        /// The message originated from the server.
        case sent = 0
        /// This message was created locally and the create event is pending.
        case pending = 1
        /// The attachment uploads failed or the server replied to the event with an error.
        case failed = 2
        /// The message send is waiting on attachment uploads.
        case waitingForAttachments = 3
    }

    public var groupId: GroupID
    public var id: MessageID
    public var threadId: ThreadID
    public var userId: UserID
    public var deletedByUserId: UserID?
    public var isRoot: Bool
    public var text: String?
    public var attachments: [EncryptedAttachment]?
    public var links: [LinkPreview]?
    public var mentions: [Mention]?
    public var sendState: SendState
    public var createTimestamp: Timestamp
    public var editTimestamp: Timestamp?

    public var isEmpty: Bool {
        text == nil && attachments == nil && links == nil
    }

    public var isDeleted: Bool {
        deletedByUserId != nil
    }

    public static let insertSubject = PassthroughSubject<MessageModel, Never>()

    public static var databaseTableName = "message"

    enum CodingKeys: String, CodingKey {
        case groupId = "message_group_id"
        case id = "message_id"
        case threadId = "message_thread_id"
        case userId = "message_user_id"
        case deletedByUserId = "message_deleted_by_user_id"
        case isRoot = "message_root"
        case text = "message_text"
        case attachments = "message_attachments"
        case links = "message_links"
        case mentions = "message_mentions"
        case sendState = "message_send_state"
        case createTimestamp = "message_create_timestamp"
        case editTimestamp = "message_edit_timestamp"
    }

    public init(
        groupId: GroupID,
        id: MessageID,
        threadId: ThreadID,
        userId: UserID,
        deletedByUserId: UserID?,
        isRoot: Bool,
        text: String?,
        attachments: [EncryptedAttachment]?,
        links: [LinkPreview]?,
        mentions: [Mention]?,
        sendState: SendState,
        createTimestamp: Timestamp,
        editTimestamp: Timestamp?
    ) {
        self.groupId = groupId
        self.id = id
        self.threadId = threadId
        self.userId = userId
        self.deletedByUserId = deletedByUserId
        self.isRoot = isRoot
        self.text = text
        self.attachments = attachments
        self.links = links
        self.mentions = mentions
        self.sendState = sendState
        self.createTimestamp = createTimestamp
        self.editTimestamp = editTimestamp
    }

    public init(
        sentPayload payload: MessagePayload,
        content: MessagePayload.Content?
    ) {
        assert(payload.messageType == .message)

        groupId = payload.groupId
        id = payload.messageId
        threadId = payload.threadId
        userId = payload.userId
        deletedByUserId = payload.deletedByUserId
        isRoot = payload.isRoot
        text = content?.text
        attachments = content?.attachments
        links = content?.links
        mentions = content?.mentions
        sendState = .sent
        createTimestamp = payload.createTimestamp
        editTimestamp = payload.editTimestamp
    }

    public init(emptyFromPayload payload: MessagePayload) {
        groupId = payload.groupId
        id = payload.messageId
        threadId = payload.threadId
        userId = payload.userId
        deletedByUserId = payload.deletedByUserId
        isRoot = payload.isRoot
        text = nil
        attachments = nil
        links = nil
        mentions = nil
        sendState = .sent
        createTimestamp = payload.createTimestamp
        editTimestamp = payload.editTimestamp
    }

    public class SupercededError: AnyError {}

    public func aroundSave(_ db: Database, save: () throws -> PersistenceSuccess) throws {
        if let existing = try Self.fetchOne(db, groupId: groupId, id: id) {
            guard existing.isSupercededBy(self) else {
                throw error(
                    "Message already exists or has been superceded. Group ID: \(groupId) Message ID: \(id)",
                    as: SupercededError.self,
                    logLevel: .info
                )
            }
        }

        _ = try save()

        try ThreadModel.upsert(db, fromMessage: self)
    }

    public func aroundInsert(_ db: Database, insert: () throws -> InsertionSuccess) throws {
        _ = try insert()

        db.afterNextTransaction { _ in
            Self.insertSubject.send(self)
        }
    }

    public static func fetchOne(_ db: Database, groupId: GroupID, id: MessageID) throws -> Self? {
        try fetchOne(
            db,
            sql: """
                    SELECT * FROM message
                    WHERE message_group_id = ? AND message_id = ?
                """,
            arguments: [groupId, id]
        )
    }

    public static func fetchExpect(_ db: Database, groupId: GroupID, id: MessageID) throws -> Self {
        try fetchExpect(
            db,
            sql: """
                    SELECT * FROM message
                    WHERE message_group_id = ? AND message_id = ?
                """,
            arguments: [groupId, id]
        )
    }

    public static func setSendState(
        _ db: Database,
        groupId: GroupID,
        id: MessageID,
        newValue: SendState
    ) throws {
        try db.execute(
            literal: """
                    UPDATE message
                    SET message_send_state = \(newValue)
                    WHERE message_id = \(id)
                        AND message_send_state != \(SendState.sent)
                """
        )
    }

    public static func setSendStateForInterrupted(_ db: Database) throws {
        try db.execute(
            literal: """
                    UPDATE message
                    SET message_send_state = \(SendState.failed)
                    WHERE message_send_state = \(SendState.waitingForAttachments)
                """
        )
    }

    public static func deleteAll(_ db: Database, groupId: GroupID) throws {
        try db.execute(
            sql: """
                    DELETE FROM message
                    WHERE message_group_id = ?
                """,
            arguments: [groupId]
        )
    }

    public static func deleteEmpty(_ db: Database, groupId: GroupID, id: MessageID) throws {
        try db.execute(
            sql: """
                    DELETE FROM message
                    WHERE message_group_id = ?
                        AND message_id = ?
                        AND message_text IS NULL
                        AND message_attachments IS NULL
                        AND message_links IS NULL
                """,
            arguments: [groupId, id]
        )
    }

    public func isSupercededBy(_ other: Self) -> Bool {
        (other.editTimestamp ?? other.createTimestamp) > (editTimestamp ?? createTimestamp)
            || other.sendState == .sent && sendState != .sent || !other.isEmpty && isEmpty
    }
}

// MARK: - Plaintext

extension MessageModel {
    public func renderPlaintext(user: UserModel?) -> String {
        assert(user?.id == userId || user == nil)
        return "\(UserModel.renderName(user)): \(renderPlaintext() ?? "")"
    }

    public func renderPlaintext() -> String? {
        guard !isEmpty else {
            return nil
        }

        var result = [String]()

        if let text, !text.isEmpty {
            result.append(text)
        }

        if let host = links?.first?.url.shortHost {
            result.append("(\(host))")
        } else if let attachments, !attachments.isEmpty {
            result.append(String(localized: "(\(attachments.count) items)"))
        }

        return result.joined(separator: " ")
    }
}

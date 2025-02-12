//
//  ThreadModel.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

import Foundation
import GRDB
import NanoCore

public struct ThreadModel: Hashable, Codable, FetchableRecord, PersistableRecord {
    public var groupId: GroupID
    public var id: ThreadID
    public var subject: String?
    public var isUnread: Bool
    public var unreadCount: Int
    public var totalCount: Int
    public var rootMessageId: MessageID?
    public var lastMessageId: MessageID?
    public var badgeTimestamp: Timestamp

    public static var databaseTableName = "thread"

    enum CodingKeys: String, CodingKey {
        case groupId = "thread_group_id"
        case id = "thread_id"
        case subject = "thread_subject"
        case isUnread = "thread_unread"
        case unreadCount = "thread_unread_count"
        case totalCount = "thread_total_count"
        case rootMessageId = "thread_root_message_id"
        case lastMessageId = "thread_last_message_id"
        case badgeTimestamp = "thread_badge_timestamp"
    }

    public static func renderSubject(_ thread: ThreadModel?) -> String {
        thread?.subject ?? String(localized: "Unnamed Thread")
    }

    public static func fetchCursor(_ db: Database, groupId: GroupID) throws -> RecordCursor<Self> {
        try fetchCursor(
            db,
            sql: """
                    SELECT * FROM thread
                    WHERE thread_group_id = ?
                """,
            arguments: [groupId]
        )
    }

    public static func fetchOne(_ db: Database, groupId: GroupID, id: ThreadID) throws -> Self? {
        try fetchOne(
            db,
            sql: """
                    SELECT * FROM thread
                    WHERE thread_group_id = ? AND thread_id = ?
                """,
            arguments: [groupId, id]
        )
    }

    public static func fetchExpect(_ db: Database, groupId: GroupID, id: ThreadID) throws -> Self {
        try fetchExpect(
            db,
            sql: """
                    SELECT * FROM thread
                    WHERE thread_group_id = ? AND thread_id = ?
                """,
            arguments: [groupId, id]
        )
    }

    public static func markRead(_ db: Database, groupId: GroupID, id: ThreadID) throws {
        try db.execute(
            sql: """
                    UPDATE thread
                    SET thread_unread = FALSE
                    WHERE thread_group_id = ? AND thread_id = ?
                """,
            arguments: [groupId, id]
        )
    }

    public static func upsert(_ db: Database, fromMessage message: MessageModel) throws {
        guard message.deletedByUserId == nil else { return }

        let session = try SessionModel.fetchExpect(db)

        try db.execute(
            literal: """
                    INSERT INTO thread (
                        thread_id,
                        thread_group_id,
                        thread_subject,
                        thread_unread,
                        \(literal: message.isRoot ? "thread_root_message_id," : "")
                        thread_last_message_id,
                        thread_badge_timestamp
                    )

                    VALUES (
                        \(message.threadId),
                        \(message.groupId),
                        \(message.isRoot && !message.isEmpty ? message.renderPlaintext() : nil),
                        \(message.userId != session.userId),
                        \(literal: message.isRoot ? "\(message.id)," : "")
                        \(message.id),
                        \(message.createTimestamp)
                    )

                    ON CONFLICT(thread_group_id, thread_id) DO UPDATE SET
                        \(literal: message.isRoot ? "thread_subject = EXCLUDED.thread_subject," : "")
                        thread_unread = IIF(
                            EXCLUDED.thread_badge_timestamp >= thread_badge_timestamp,
                            EXCLUDED.thread_unread,
                            thread_unread
                        ),
                        \(literal: message.isRoot ? "thread_root_message_id = EXCLUDED.thread_root_message_id," : "")
                        thread_last_message_id = IIF(
                            EXCLUDED.thread_badge_timestamp >= thread_badge_timestamp,
                            EXCLUDED.thread_last_message_id,
                            thread_last_message_id
                        ),
                        thread_badge_timestamp = MAX(
                            thread_badge_timestamp,
                            EXCLUDED.thread_badge_timestamp
                        )
                """
        )
    }

    public static func update(_ db: Database, from activity: ThreadActivityPayload) throws {
        try db.execute(
            sql: """
                    UPDATE thread
                    SET thread_unread = ?,
                        thread_unread_count = ?,
                        thread_total_count = ?
                    WHERE thread_group_id = ? AND thread_id = ?
                """,
            arguments: [
                activity.isUnread,
                activity.unreadCount,
                activity.totalCount,
                activity.groupId,
                activity.threadId,
            ]
        )
    }

    public static func deleteAll(_ db: Database, groupId: GroupID) throws {
        try db.execute(
            sql: """
                    DELETE FROM thread
                    WHERE thread_group_id = ?
                """,
            arguments: [groupId]
        )
    }
}

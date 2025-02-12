//
//  Group.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

import Foundation
import GRDB
import NanoCore

public struct GroupModel: Identifiable, Codable, Equatable, FetchableRecord, PersistableRecord {
    public var id: GroupID
    public var name: String
    public var image: EncryptedAttachment?
    public var emoji: String?
    public var isPending: Bool
    public var isUnread: Bool
    public var unreadCount: Int
    public var badgeTimestamp: Timestamp

    public static var databaseTableName = "group"

    enum CodingKeys: String, CodingKey {
        case id = "group_id"
        case name = "group_name"
        case image = "group_image"
        case emoji = "group_emoji"
        case isPending = "group_pending"
        case isUnread = "group_unread"
        case unreadCount = "group_unread_count"
        case badgeTimestamp = "group_badge_timestamp"
    }

    public init(
        id: GroupID,
        name: String? = nil,
        image: EncryptedAttachment? = nil,
        emoji: String? = nil,
        isPending: Bool = true,
        isUnread: Bool = true,
        unreadCount: Int = 0,
        badgeTimestamp: Timestamp = .now()
    ) {
        self.id = id
        self.name = name ?? "\(id)"
        self.image = image
        self.emoji = emoji
        self.isPending = isPending
        self.isUnread = isUnread
        self.unreadCount = unreadCount
        self.badgeTimestamp = badgeTimestamp
    }

    public static func renderName(_ group: GroupModel?) -> String {
        group?.name ?? String(localized: "Unknown Group")
    }

    public static func fetchExpect(_ db: Database, id: GroupID, isPending: Bool) throws -> Self {
        try fetchExpect(
            db,
            sql: """
                    SELECT * FROM `group`
                    WHERE group_id = ? AND group_pending = ?
                """,
            arguments: [id, isPending]
        )
    }

    public static func fetchAll(_ db: Database, isPending: Bool) throws -> [Self] {
        try fetchAll(
            db,
            sql: """
                    SELECT * FROM `group`
                    WHERE group_pending = ?
                """,
            arguments: [isPending]
        )
    }

    public static func upsert(_ db: Database, from payload: GroupPayload) throws {
        try db.execute(
            literal: """
                    INSERT INTO `group` (
                        group_id,
                        group_name,
                        group_pending,
                        group_unread,
                        group_unread_count,
                        group_badge_timestamp
                    )
                    VALUES (
                        \(payload.groupId),
                        \(payload.groupId),
                        \(false),
                        \(true),
                        \(0),
                        \(Timestamp.now())
                    )

                    ON CONFLICT (group_id) DO UPDATE
                    SET group_pending = EXCLUDED.group_pending
                """
        )
    }

    public static func upsert(
        _ db: Database,
        id: GroupID,
        from metadata: MetadataPayload.Content
    ) throws {
        try db.execute(
            literal: """
                    INSERT INTO `group` (
                        group_id,
                        group_name,
                        group_image,
                        group_emoji,
                        group_pending,
                        group_unread,
                        group_unread_count,
                        group_badge_timestamp
                    )
                    VALUES (
                        \(id),
                        \(metadata.name),
                        \(metadata.image),
                        \(metadata.emoji),
                        \(true),
                        \(true),
                        \(0),
                        \(Timestamp.now())
                    )

                    ON CONFLICT (group_id) DO UPDATE
                    SET group_name = EXCLUDED.group_name,
                        group_image = EXCLUDED.group_image,
                        group_emoji = EXCLUDED.group_emoji
                """
        )
    }

    public static func upsert(_ db: Database, from activity: GroupActivityPayload) throws {
        try db.execute(
            literal: """
                    INSERT INTO `group` (
                        group_id,
                        group_name,
                        group_pending,
                        group_unread,
                        group_unread_count,
                        group_badge_timestamp
                    )
                    VALUES (
                        \(activity.groupId),
                        \(activity.groupId),
                        \(true),
                        \(activity.isUnread),
                        \(activity.unreadCount),
                        \(activity.badgeTimestamp)
                    )

                    ON CONFLICT (group_id) DO UPDATE
                    SET group_unread = EXCLUDED.group_unread,
                        group_unread_count = EXCLUDED.group_unread_count,
                        group_badge_timestamp = EXCLUDED.group_badge_timestamp
                """
        )
    }

    public static func markRead(_ db: Database, groupId: GroupID) throws {
        try db.execute(
            sql: """
                    UPDATE `group`
                    SET group_unread = FALSE
                    WHERE group_id = ?
                """,
            arguments: [groupId]
        )
    }
}

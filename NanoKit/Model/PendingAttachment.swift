//
//  PendingAttachment.swift
//  NanoKit
//
//  Created by Richard Henry on 2/12/24.
//

import Foundation
import GRDB
import NanoCore
import UniformTypeIdentifiers

public struct PendingAttachment: Codable, FetchableRecord, PersistableRecord {
    public var groupId: GroupID
    public var messageId: MessageID
    public var assetKey: String
    public var isUploadComplete = false

    public static var databaseTableName = "pending_attachment"

    enum CodingKeys: String, CodingKey {
        case groupId = "attachment_group_id"
        case messageId = "attachment_message_id"
        case assetKey = "attachment_asset_key"
        case isUploadComplete = "attachment_upload_complete"
    }

    public static func fetchIncompleteCount(
        _ db: Database,
        groupId: GroupID,
        messageId: MessageID
    ) throws -> Int {
        try Int.fetchOne(
            db,
            sql: """
                    SELECT COUNT(*) FROM pending_attachment
                    WHERE attachment_group_id = ?
                        AND attachment_message_id = ?
                        AND attachment_upload_complete IS FALSE
                """,
            arguments: [groupId, messageId]
        ) ?! error("Count query did not return a value.")
    }

    public static func fetchIncomplete(
        _ db: Database,
        groupId: GroupID,
        messageId: MessageID
    ) throws -> [PendingAttachment] {
        try PendingAttachment.fetchAll(
            db,
            sql: """
                    SELECT * FROM pending_attachment
                    WHERE attachment_group_id = ?
                        AND attachment_message_id = ?
                        AND attachment_upload_complete IS FALSE
                """,
            arguments: [groupId, messageId]
        )
    }
}

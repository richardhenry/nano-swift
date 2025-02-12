//
//  GroupActivityModel.swift
//  NanoKit
//
//  Created by Richard Henry on 5/7/24.
//

import Foundation
import GRDB
import NanoCore

public struct GroupActivityModel: Identifiable, Codable, Equatable {
    public var id: GroupID
    public var timestamp: Timestamp

    public func maybeSave(_ db: Database) throws {
        try db.execute(
            sql: """
                    INSERT INTO group_activity (
                        group_activity_id,
                        group_activity_dirty,
                        group_activity_timestamp
                    )
                    VALUES(?, TRUE, ?)

                    ON CONFLICT (group_activity_id) DO UPDATE

                    SET group_activity_dirty = TRUE,
                        group_activity_timestamp = EXCLUDED.group_activity_timestamp

                    WHERE EXCLUDED.group_activity_timestamp
                        > group_activity.group_activity_timestamp
                """,
            arguments: [id, timestamp]
        )
    }

    public static func fetchDirty(_ db: Database) throws -> [FetchKey] {
        try SQLRequest<Row>(
            sql: """
                    SELECT group_activity_id
                    FROM group_activity
                    WHERE group_activity_dirty IS TRUE
                    ORDER BY group_activity_timestamp DESC
                """
        )
        .fetchAll(db)
        .map {
            let groupId: GroupID = $0["group_activity_id"]
            return FetchKey(fetchType: .threadActivity, path: groupId)
        }
    }

    public static func fetchMaxActivityTimestamp(_ db: Database) throws -> Timestamp? {
        try SQLRequest<Timestamp>(
            sql: """
                    SELECT group_activity_timestamp
                    FROM group_activity
                    ORDER BY group_activity_timestamp DESC
                    LIMIT 1
                """
        )
        .fetchOne(db)
    }

    public static func completion(_ db: Database, key: FetchKey) throws {
        guard key.fetchType == .threadActivity else {
            throw error("Unexpected fetch type: \(key.fetchType)")
        }

        let groupId = try key.path.groupId

        try db.execute(
            literal: """
                    UPDATE group_activity
                    SET group_activity_dirty = FALSE
                    WHERE group_activity_id = \(groupId)
                        AND group_activity_timestamp <= (
                            SELECT MAX(cursor_start_timestamp) FROM cursor
                            WHERE cursor_fetch_type = \(FetchType.threadActivity)
                                AND cursor_path = \(key.path)
                            GROUP BY cursor_fetch_type, cursor_path
                            LIMIT 1
                        )
                """
        )

        log(.debug, "Handled fetch completion: \(key) Updates: \(db.changesCount)")
    }

    public static func deleteAll(_ db: Database, id: GroupID) throws {
        try db.execute(
            literal: """
                    DELETE FROM group_activity
                    WHERE group_activity_id = \(id)
                """
        )
    }
}

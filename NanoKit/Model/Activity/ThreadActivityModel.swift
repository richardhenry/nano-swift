//
//  ThreadActivityModel.swift
//  NanoKit
//
//  Created by Richard Henry on 5/7/24.
//

import Foundation
import GRDB
import NanoCore

public struct ThreadActivityModel: Identifiable, Codable, Equatable {
    public var groupId: GroupID
    public var id: ThreadID
    public var timestamp: Timestamp

    public func maybeSave(_ db: Database) throws {
        try db.execute(
            sql: """
                    INSERT INTO thread_activity (
                        thread_activity_group_id,
                        thread_activity_id,
                        thread_activity_dirty,
                        thread_activity_timestamp
                    )
                    VALUES(?, ?, TRUE, ?)

                    ON CONFLICT (thread_activity_group_id, thread_activity_id) DO UPDATE

                    SET thread_activity_dirty = TRUE,
                        thread_activity_timestamp = EXCLUDED.thread_activity_timestamp

                    WHERE EXCLUDED.thread_activity_timestamp
                        > thread_activity.thread_activity_timestamp
                """,
            arguments: [groupId, id, timestamp]
        )
    }

    public static func fetchDirty(_ db: Database) throws -> [FetchKey] {
        try SQLRequest<Row>(
            sql: """
                    SELECT thread_activity_group_id, thread_activity_id
                    FROM thread_activity
                    WHERE thread_activity_dirty IS TRUE
                    ORDER BY thread_activity_timestamp DESC
                """
        )
        .fetchAll(db)
        .map {
            let groupId: GroupID = $0["thread_activity_group_id"]
            let threadId: ThreadID = $0["thread_activity_id"]
            return FetchKey(fetchType: .message, path: groupId, threadId)
        }
    }

    public static func completion(_ db: Database, key: FetchKey) throws {
        guard key.fetchType == .message else {
            throw error("Unexpected fetch type: \(key.fetchType)")
        }

        let (groupId, threadId) = try (key.path.groupId, key.path.threadId)

        try db.execute(
            literal: """
                    UPDATE thread_activity
                    SET thread_activity_dirty = FALSE
                    WHERE thread_activity_group_id = \(groupId)
                        AND thread_activity_id = \(threadId)
                        AND thread_activity_timestamp <= (
                            SELECT MAX(cursor_start_timestamp) FROM cursor
                            WHERE cursor_fetch_type = \(FetchType.message)
                                AND cursor_path = \(key.path)
                            GROUP BY cursor_fetch_type, cursor_path
                            LIMIT 1
                        )
                """
        )

        log(.debug, "Handled fetch completion: \(key) Updates: \(db.changesCount)")
    }

    public static func deleteAll(_ db: Database, groupId: GroupID) throws {
        try db.execute(
            literal: """
                    DELETE FROM thread_activity
                    WHERE thread_activity_group_id = \(groupId)
                """
        )
    }
}

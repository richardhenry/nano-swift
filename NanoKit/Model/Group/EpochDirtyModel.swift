//
//  EpochDirtyModel.swift
//  NanoKit
//
//  Created by Richard Henry on 3/27/24.
//

import Foundation
import GRDB
import NanoCore

public struct EpochDirtyModel: Codable, Identifiable, FetchableRecord, PersistableRecord {
    public static let maximumLifetime: Timestamp = .days(7)

    public var id: GroupID
    public var lastEpochTimestamp: Timestamp?
    public var dirtyTimestamp: Timestamp?

    public static var databaseTableName = "epoch_dirty"

    enum CodingKeys: String, CodingKey {
        case id = "epoch_dirty_group_id"
        case lastEpochTimestamp = "epoch_dirty_last_epoch_timestamp"
        case dirtyTimestamp = "epoch_dirty_timestamp"
    }

    public static func set(_ db: Database, id: GroupID, lastEpochTimestamp: Timestamp) throws {
        try db.execute(
            sql: """
                    INSERT INTO epoch_dirty (
                        epoch_dirty_group_id,
                        epoch_dirty_last_epoch_timestamp
                    ) VALUES (?, ?)

                    ON CONFLICT (epoch_dirty_group_id) DO UPDATE
                    SET epoch_dirty_last_epoch_timestamp = EXCLUDED.epoch_dirty_last_epoch_timestamp

                    WHERE EXCLUDED.epoch_dirty_last_epoch_timestamp > epoch_dirty_last_epoch_timestamp
                        OR epoch_dirty_last_epoch_timestamp IS NULL
                """,
            arguments: [id, lastEpochTimestamp]
        )
    }

    public static func set(_ db: Database, id: GroupID, dirtyTimestamp: Timestamp) throws {
        try db.execute(
            sql: """
                    INSERT INTO epoch_dirty (
                        epoch_dirty_group_id,
                        epoch_dirty_timestamp
                    ) VALUES (?, ?)

                    ON CONFLICT (epoch_dirty_group_id) DO UPDATE
                    SET epoch_dirty_timestamp = EXCLUDED.epoch_dirty_timestamp

                    WHERE EXCLUDED.epoch_dirty_timestamp > epoch_dirty_timestamp
                        OR epoch_dirty_timestamp IS NULL
                """,
            arguments: [id, dirtyTimestamp]
        )
    }

    public static func fetchDirty(
        _ db: Database,
        now: Timestamp = .now()
    ) throws -> [EpochDirtyModel] {
        try fetchAll(
            db,
            sql: """
                    SELECT * FROM epoch_dirty
                    WHERE epoch_dirty_timestamp > epoch_dirty_last_epoch_timestamp
                        OR (? - epoch_dirty_last_epoch_timestamp) > ?
                """,
            arguments: [now, maximumLifetime]
        )
    }
}

//
//  EpochModel.swift
//  Nano
//
//  Created by Richard Henry on 1/6/24.
//

import CryptoKit
import Foundation
import GRDB
import MessagePack
import NanoCore
import NanoCrypto

public struct EpochModel: Codable, FetchableRecord, PersistableRecord {
    public var groupId: GroupID
    public var id: EpochID
    public var sequenceId: UInt32
    public var isDiscontiguous: Bool
    public var timestamp: Timestamp

    public static var databaseTableName = "epoch"

    enum CodingKeys: String, CodingKey {
        case groupId = "epoch_group_id"
        case id = "epoch_id"
        case sequenceId = "epoch_sequence_id"
        case isDiscontiguous = "epoch_discontiguous"
        case timestamp = "epoch_timestamp"
    }

    public init(
        groupId: GroupID,
        id: EpochID,
        sequenceId: UInt32,
        isDiscontiguous: Bool,
        timestamp: Timestamp
    ) {
        self.groupId = groupId
        self.id = id
        self.sequenceId = sequenceId
        self.isDiscontiguous = isDiscontiguous
        self.timestamp = timestamp
    }

    public init(payload: EpochPayload, isDiscontiguous: Bool) {
        self.groupId = payload.groupId
        self.id = payload.epochId
        self.sequenceId = payload.sequenceId
        self.isDiscontiguous = isDiscontiguous
        self.timestamp = payload.timestamp
    }

    public static func fetchAll(
        _ db: Database,
        groupId: GroupID,
        includeDiscontiguous: Bool,
        limit: Int? = nil
    ) throws -> [Self] {
        var sql: SQL = """
                SELECT * FROM epoch
                WHERE epoch_group_id = \(groupId)
            """

        if !includeDiscontiguous {
            sql += """
                    AND epoch_discontiguous IS FALSE
                """
        }

        sql += """
                ORDER BY epoch_timestamp ASC
            """

        if let limit {
            sql += """
                    LIMIT \(limit)
                """
        }

        return try SQLRequest<Self>(literal: sql).fetchAll(db)
    }

    public static func fetchCurrent(_ db: Database, groupId: GroupID) throws -> Self {
        try fetchExpect(
            db,
            sql: """
                    SELECT * FROM epoch
                    WHERE epoch_group_id = ?
                    ORDER BY epoch_timestamp DESC
                """,
            arguments: [groupId]
        )
    }

    public static func fetchOldestContiguous(_ db: Database, groupId: GroupID) throws -> Self {
        try fetchAll(db, groupId: groupId, includeDiscontiguous: false, limit: 1).first
            ?! error("Epoch not found. Group ID: \(groupId)")
    }

    public static func fetchOne(
        _ db: Database,
        groupId: GroupID,
        id: EpochID
    ) throws -> EpochModel? {
        try fetchOne(
            db,
            sql: """
                    SELECT * FROM epoch
                    WHERE epoch_group_id = ? AND epoch_id = ?
                """,
            arguments: [groupId, id]
        )
    }

    public static func fetchExpect(
        _ db: Database,
        groupId: GroupID,
        id: EpochID
    ) throws -> EpochModel {
        try fetchOne(db, groupId: groupId, id: id)
            ?! error("Epoch not found. Group ID: \(groupId) Epoch ID: \(id)")
    }

    public static func deleteAll(_ db: Database, groupId: GroupID) throws {
        try db.execute(
            sql: """
                    DELETE FROM epoch
                    WHERE epoch_group_id = ?
                """,
            arguments: [groupId]
        )
    }

    public func aroundSave(_ db: Database, save: () throws -> PersistenceSuccess) throws {
        _ = try save()
        try EpochDirtyModel.set(db, id: groupId, lastEpochTimestamp: timestamp)
    }

    public static func markContiguous(_ db: Database, groupId: GroupID, id: EpochID) throws {
        try db.execute(
            literal: """
                    UPDATE epoch
                    SET epoch_discontiguous = FALSE
                    WHERE epoch_group_id = \(groupId)
                        AND epoch_id = \(id)
                """
        )

        log(.info, "Marked epoch as contiguous. Group ID: \(groupId) Epoch ID: \(id)")
    }
}

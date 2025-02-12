//
//  CursorModel.swift
//  NanoKit
//
//  Created by Richard Henry on 5/2/24.
//

import Foundation
import GRDB

public struct CursorModel: FetchableRecord, PersistableRecord, Equatable {
    public var key: FetchKey
    /// The newest index.
    public var start: FetchIndex
    /// The oldest "one past the end" index.
    public var end: FetchIndex?

    /// If true, there are no older pages remaining.
    public var isExhausted: Bool {
        end == nil
    }

    public static var databaseTableName = "cursor"

    public init(key: FetchKey, start: FetchIndex, end: FetchIndex?) {
        self.key = key
        self.start = start
        self.end = end
    }

    public init?(payload: CursorPayload) {
        guard let start = payload.start else { return nil }

        self.key = payload.key
        self.start = start
        self.end = payload.end
    }

    public init(row: Row) throws {
        key = .init(
            fetchType: row["cursor_fetch_type"],
            path: row["cursor_path"]
        )

        start = .init(
            timestamp: row["cursor_start_timestamp"],
            id: row["cursor_start_id"]
        )

        if let timestamp = row["cursor_end_timestamp"] as? Int64 {
            end = .init(
                timestamp: timestamp,
                id: row["cursor_end_id"]
            )
        } else {
            end = nil
        }
    }

    public func encode(to container: inout PersistenceContainer) throws {
        container["cursor_fetch_type"] = key.fetchType
        container["cursor_path"] = key.path
        container["cursor_start_timestamp"] = start.timestamp
        container["cursor_start_id"] = start.id
        container["cursor_end_timestamp"] = end?.timestamp
        container["cursor_end_id"] = end?.id
    }

    /// Queries for cursors that overlap with the start and end index of this cursor and expands this cursor to include those ranges.
    ///
    /// You must call this method before you save a cursor.
    public mutating func extend(_ db: Database) throws {
        if let existing = try Self.fetchContaining(db, key: key, index: start) {
            start = existing.start
        }

        if let end, let existing = try Self.fetchContaining(db, key: key, index: end) {
            self.end = existing.end
        }
    }

    public func aroundSave(_ db: Database, save: () throws -> PersistenceSuccess) throws {
        try Self.deleteRedundant(db, withCursor: self)
        _ = try save()
    }

    public static func fetchAll(_ db: Database, key: FetchKey, limit: Int? = nil) throws -> [Self] {
        var sql: SQL = """
                SELECT * FROM cursor
                WHERE cursor_fetch_type = \(key.fetchType)
                    AND cursor_path = \(key.path)
                ORDER BY cursor_start_timestamp DESC, cursor_start_id ASC
            """

        if let limit {
            sql += """
                    LIMIT \(limit)
                """
        }

        return try SQLRequest<Self>(literal: sql).fetchAll(db)
    }

    public static func fetchOne(_ db: Database, key: FetchKey) throws -> Self? {
        try fetchAll(db, key: key, limit: 1).first
    }

    public static func fetchContaining(
        _ db: Database,
        key: FetchKey,
        index: FetchIndex
    ) throws -> Self? {
        return try SQLRequest<Self>(
            literal: """
                    SELECT * FROM cursor
                    WHERE cursor_fetch_type = \(key.fetchType)
                        AND cursor_path = \(key.path)
                        AND (
                            cursor_start_timestamp > \(index.timestamp)
                            OR (
                                cursor_start_timestamp = \(index.timestamp)
                                AND cursor_start_id <= \(index.id)
                            )
                        )
                        AND (
                            cursor_end_timestamp IS NULL
                            OR cursor_end_timestamp < \(index.timestamp)
                            OR (
                                cursor_end_timestamp = \(index.timestamp)
                                AND cursor_end_id >= \(index.id)
                            )
                        )
                """
        )
        .fetchOne(db)
    }

    public static func deleteAll(_ db: Database, fetchType: FetchType, path: FetchPath) throws {
        try db.execute(
            literal: """
                    DELETE FROM cursor
                    WHERE cursor_fetch_type = \(fetchType)
                        AND cursor_path = \(path)
                """
        )
    }

    public static func deleteAll(
        _ db: Database,
        fetchType: FetchType
    ) throws {
        try db.execute(
            literal: """
                    DELETE FROM cursor
                    WHERE cursor_fetch_type = \(fetchType)
                """
        )
    }

    public static func deleteAll(
        _ db: Database,
        fetchType: FetchType,
        path: any UniqueIdentifier...
    ) throws {
        try deleteAll(db, fetchType: fetchType, path: FetchPath(path))
    }

    public static func deleteAll(
        _ db: Database,
        fetchType: FetchType,
        withPathPrefix path: FetchPath
    ) throws {
        try db.execute(
            literal: """
                    DELETE FROM cursor
                    WHERE cursor_fetch_type = \(fetchType)
                        AND cursor_path LIKE \("\(path)%")
                """
        )
    }

    public static func deleteAll(
        _ db: Database,
        fetchType: FetchType,
        withPathPrefix path: any UniqueIdentifier...
    ) throws {
        try deleteAll(db, fetchType: fetchType, withPathPrefix: FetchPath(path))
    }

    public static func deleteRedundant(_ db: Database, withCursor cursor: Self) throws {
        var sql: SQL = """
                DELETE FROM cursor
                WHERE cursor_fetch_type = \(cursor.key.fetchType)
                    AND cursor_path = \(cursor.key.path)
                    AND (
                        cursor_start_timestamp < \(cursor.start.timestamp)
                        OR (
                            cursor_start_timestamp = \(cursor.start.timestamp)
                            AND cursor_start_id >= \(cursor.start.id)
                        )
                    )
            """

        if let end = cursor.end {
            sql += """
                    AND (
                        cursor_end_timestamp > \(end.timestamp)
                        OR (
                            cursor_end_timestamp = \(end.timestamp)
                            AND cursor_end_id <= \(end.id)
                        )
                    )
                """
        }

        try db.execute(literal: sql)
    }
}

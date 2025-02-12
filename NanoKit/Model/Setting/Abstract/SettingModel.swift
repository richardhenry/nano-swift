//
//  SettingModel.swift
//  NanoKit
//
//  Created by Richard Henry on 4/3/24.
//

import Foundation
import GRDB

public protocol SettingModel: Codable, FetchableRecord, PersistableRecord {
    static var keyColumns: [Column] { get }
    static var isOptimisticColumn: Column { get }
    static var valueColumn: Column { get }
    var key: [any DatabaseValueConvertible] { get }
    var isOptimistic: Bool { get }
}

extension SettingModel {
    static func prepareFetchValue(
        key: [DatabaseValueConvertible],
        columnExpression: String
    ) -> (sql: String, arguments: StatementArguments) {
        assert(key.count == keyColumns.count)

        var sql = """
                SELECT \(columnExpression) FROM \(databaseTableName)
            """

        for (idx, column) in keyColumns.enumerated() {
            if idx == 0 {
                sql += " WHERE"
            } else {
                sql += " AND"
            }

            sql += " \(column.name) = ?"
        }

        sql += """
                ORDER BY \(isOptimisticColumn.name) DESC
            """

        return (sql, StatementArguments(key))
    }

    public static func fetchOne(_ db: Database, key: [DatabaseValueConvertible]) throws -> Self? {
        let (sql, arguments) = prepareFetchValue(key: key, columnExpression: "*")
        return try Self.fetchOne(db, sql: sql, arguments: arguments)
    }

    public static func fetchValue<Value: DatabaseValueConvertible>(
        _ db: Database,
        key: [DatabaseValueConvertible]
    ) throws -> Value? {
        let (sql, arguments) = prepareFetchValue(key: key, columnExpression: valueColumn.name)
        return try SQLRequest<Value>(sql: sql, arguments: arguments).fetchOne(db)
    }

    public static func fetchValue<Value: SettingValue>(
        _ db: Database,
        key: [DatabaseValueConvertible],
        defaultValue: Value
    ) throws -> Value {
        try fetchValue(db, key: key) ?? defaultValue
    }

    public static func deleteOptimistic(_ db: Database, key: [DatabaseValueConvertible]) throws {
        assert(key.count == keyColumns.count)

        var sql = """
                DELETE FROM \(Self.databaseTableName)
                WHERE \(Self.isOptimisticColumn.name) IS TRUE
            """

        for column in Self.keyColumns {
            sql += " AND \(column.name) = ?"
        }

        try db.execute(sql: sql, arguments: StatementArguments(key))
    }

    public static func deleteAll(_ db: Database, key: [DatabaseValueConvertible]) throws {
        assert(key.count == keyColumns.count)

        var sql = """
                DELETE FROM \(Self.databaseTableName)
            """

        for column in Self.keyColumns {
            sql += " AND \(column.name) = ?"
        }

        try db.execute(sql: sql, arguments: StatementArguments(key))
    }

    public func aroundSave(_ db: Database, save: () throws -> PersistenceSuccess) throws {
        _ = try save()

        if !isOptimistic {
            // Delete the optimistic counterpart for this row when saving a non-optimistic value.
            try Self.deleteOptimistic(db, key: key)
        }
    }
}

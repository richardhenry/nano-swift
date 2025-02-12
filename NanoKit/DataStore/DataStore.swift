//
//  DataStore.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

import Foundation
import GRDB
import NanoCore
import NanoCrypto
import SwiftUI

@Observable public class DataStore {
    public func write<T>(_ updates: (Database) throws -> T) throws -> T {
        try dbWriter.write(updates)
    }

    public func write<T>(_ updates: @Sendable @escaping (Database) throws -> T) async throws -> T {
        try await dbWriter.write(updates)
    }

    public func read<T>(_ value: (Database) throws -> T) throws -> T {
        try dbReader.read(value)
    }

    public func read<T>(_ value: @Sendable @escaping (Database) throws -> T) async throws -> T {
        try await dbReader.read(value)
    }

    init(_ writer: any DatabaseWriter) throws {
        self.dbWriter = writer
        try migrator.migrate(writer)
    }

    public let dbWriter: any DatabaseWriter

    public var dbReader: DatabaseReader {
        dbWriter
    }

    /// The database for the application.
    public static let shared: DataStore = {
        do {
            let fileManager = FileManager.default

            let directoryURL = try fileManager.secureAppGroupDirectory(path: "Database")
            var databaseURL = directoryURL.appending(path: "db.sqlite")

            log(
                .info,
                "opened db: \(databaseURL.path(percentEncoded: false).replacingOccurrences(of: " ", with: "\\ "))"
            )

            if !fileManager.fileExists(atPath: databaseURL.path) {
                // Create an empty db file so that encryption and backup exclusion can be enabled.
                fileManager.createFile(atPath: databaseURL.path, contents: nil)
            }
            try fileManager.makeSecure(&databaseURL)

            let dbPool = try DatabasePool(path: databaseURL.path)
            return try DataStore(dbPool)
        } catch {
            fatalError("Unhandled error: \(error)")
        }
    }()

    /// An empty in-memory database queue for unit testing.
    public static func ephemeral() -> DataStore {
        var config = Configuration()
        config.publicStatementArguments = true
        config.prepareDatabase { db in
            db.trace { log(.debug, "sql: \($0)") }
        }
        let dbQueue = try! DatabaseQueue(configuration: config)
        return try! DataStore(dbQueue)
    }

    /// An array of user IDs in a preview database. In other databases, this will be empty.
    public var previewUserIds = [UserID]()

    /// An mapping of group IDs in a preview database to its thread IDs. In other databases, this will be empty.
    public var previewGroupIdToThreadIds = [GroupID: [ThreadID]]()

    /// Creates an in-memory database queue for SwiftUI previews.
    public static func preview() -> DataStore {
        let dataStore = ephemeral()
        #if DEBUG
        try! dataStore.installFixtures()
        #endif
        return dataStore
    }

    /// Erase all tables in the database, re-run migrations, and notify all database observers.
    public func deleteAll() throws {
        log(.info, "Deleting all data.")

        // Don't delete cloud keychain items or we may lose the ephemeral recovery key.
        try KeychainStorage.shared.deleteAll(mode: .local)

        try write { db in
            let tableNames = try String.fetchAll(
                db,
                sql: """
                        SELECT name FROM sqlite_master
                        WHERE type = 'table'
                            AND name NOT LIKE 'sqlite_%'
                    """
            )

            for tableName in tableNames {
                try db.execute(sql: "DROP TABLE IF EXISTS `\(tableName)`")
            }
        }

        try migrator.migrate(dbWriter)

        try write { db in
            try db.notifyChanges(in: .fullDatabase)
        }
    }
}

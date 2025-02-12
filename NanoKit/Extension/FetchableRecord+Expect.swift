//
//  FetchableRecord+Expect.swift
//  NanoKit
//
//  Created by Richard Henry on 2/4/24.
//

import GRDB
import NanoCore

extension FetchableRecord where Self: TableRecord & Identifiable, ID: DatabaseValueConvertible {
    public static func fetchExpect(
        _ db: Database,
        id: ID,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) throws -> Self {
        try fetchOne(db, id: id)
            ?! error(
                "\(Self.self) not found. ID: \(id)",
                file: file,
                function: function,
                line: line
            )
    }
}

extension FetchableRecord where Self: TableRecord {
    public static func fetchExpect(
        _ db: Database,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) throws -> Self {
        try fetchOne(db)
            ?! error("\(Self.self) not found.", file: file, function: function, line: line)
    }

    public static func fetchExpect(
        _ db: Database,
        sql: String,
        arguments: StatementArguments = StatementArguments(),
        adapter: (any RowAdapter)? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) throws -> Self {
        try fetchOne(db, sql: sql, arguments: arguments, adapter: adapter)
            ?! error("\(Self.self) not found.", file: file, function: function, line: line)
    }
}

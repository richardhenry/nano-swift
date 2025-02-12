//
//  FetchPath.swift
//  NanoKit
//
//  Created by Richard Henry on 5/11/24.
//

import Foundation
import GRDB
import NanoCore

public struct FetchPath: Hashable {
    public var value: [AnyID]

    public var groupId: GroupID {
        get throws {
            if let groupId = value.first {
                return groupId.asType()
            } else {
                throw error("Path is missing a group ID.")
            }
        }
    }

    public var threadId: ThreadID {
        get throws {
            if let threadId = value[ifExists: 1] {
                return threadId.asType()
            } else {
                throw error("Path is missing a thread ID.")
            }
        }
    }

    init(_ path: [any UniqueIdentifier]) {
        value = path.map { $0.eraseToAny() }
    }
}

extension FetchPath: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode([AnyID].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension FetchPath: CustomStringConvertible {
    public var description: String {
        value.map { $0.description }.joined(separator: ",")
    }
}

extension FetchPath: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        description.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> FetchPath? {
        if let stringValue = String.fromDatabaseValue(dbValue) {
            let parts = stringValue.split(separator: ",")
            let path = parts.compactMap { AnyID(uuidString: String($0)) }

            if parts.count == path.count {
                return FetchPath(path)
            } else {
                log(.warning, "Failed to decode: \(stringValue)")
                return nil
            }

        } else {
            log(.warning, "Failed to decode string from: \(dbValue)")
            return nil
        }
    }
}

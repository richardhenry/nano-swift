//
//  SessionModel.swift
//  Nano
//
//  Created by Richard Henry on 1/4/24.
//

import Combine
import CryptoKit
import Foundation
import GRDB
import NanoCore

public struct SessionModel: Codable, Hashable, FetchableRecord, PersistableRecord {
    public var userId: UserID
    public var sessionId: Int32
    public var token: String
    public var timestamp: Timestamp

    public static let valuePublisher: AnyPublisher<SessionModel?, any Error> =
        ValueObservation
        .tracking { db in try? fetchOne(db) }
        .shared(in: DataStore.shared.dbReader, scheduling: .immediate)
        .publisher()
        .eraseToAnyPublisher()

    public static var databaseTableName = "session"

    private var id = 1  // Single row table.

    enum CodingKeys: String, CodingKey {
        case id = "session_local_id"
        case userId = "session_user_id"
        case sessionId = "session_session_id"
        case token = "session_token"
        case timestamp = "session_timestamp"
    }

    public init(userId: UserID, sessionId: Int32, token: String, timestamp: Timestamp) {
        self.userId = userId
        self.sessionId = sessionId
        self.token = token
        self.timestamp = timestamp
    }

    @discardableResult
    public func replace(_ db: Database) throws -> SessionModel {
        try upsertAndFetch(db, onConflict: ["session_local_id"], doUpdate: nil)
    }
}

//
//  UserKeyModel.swift
//  Nano
//
//  Created by Richard Henry on 1/6/24.
//

import CryptoKit
import Foundation
import GRDB
import NanoCore

public struct UserKeyModel: Codable, Equatable, Identifiable, FetchableRecord, PersistableRecord {
    public var id: UserID
    public var signing: Curve25519.Signing.PublicKey
    public var timestamp: Timestamp

    public static var databaseTableName = "user_key"

    enum CodingKeys: String, CodingKey {
        case id = "user_key_id"
        case signing = "user_key_signing"
        case timestamp = "user_key_timestamp"
    }

    public init(payload: UserKeyPayload) {
        id = payload.userId
        signing = payload.signingKey
        timestamp = payload.timestamp
    }

    public init(id: UserID, signing: Curve25519.Signing.PublicKey, timestamp: Timestamp) {
        self.id = id
        self.signing = signing
        self.timestamp = timestamp
    }

    public func willUpdate(_ db: Database, columns: Set<String>) throws {
        throw error("User key cannot be updated after it is inserted. User ID: \(id)")
    }
}

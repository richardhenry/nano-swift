//
//  UserKeyPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/6/24.
//

import CryptoKit
import Foundation
import NanoCore

public struct UserKeyPayload: Codable {
    public var userId: UserID
    public var timestamp: Timestamp
    public var signingKey: Curve25519.Signing.PublicKey

    enum CodingKeys: String, CodingKey {
        case userId = "u"
        case timestamp = "x"
        case signingKey = "s"
    }

    public init(userKey: UserKeyModel) throws {
        userId = userKey.id
        timestamp = userKey.timestamp
        signingKey = userKey.signing
    }
}

extension UserKeyPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        try await DataStore.shared.write { db in
            // NB: We intentionally do not allow a user key to be updated after creation. This would break the system trust model.
            try UserKeyModel(payload: self).insert(db, onConflict: .ignore)
        }
    }
}

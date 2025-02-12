//
//  SessionSecretSecret.swift
//  Nano
//
//  Created by Richard Henry on 1/4/24.
//

import CryptoKit
import Foundation
import NanoCore

public struct SessionSecretPayload: Codable {
    public var userId: UserID
    public var sessionId: Int32
    public var token: String
    public var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case userId = "u"
        case sessionId = "d"
        case token = "s"
        case timestamp = "x"
    }
}

extension SessionSecretPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        try await DataStore.shared.write { db in
            _ = try SessionModel(
                userId: userId,
                sessionId: sessionId,
                token: token,
                timestamp: timestamp
            )
            .replace(db)
        }
    }
}

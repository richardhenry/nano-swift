//
//  PushPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/26/24.
//

import Foundation
import NanoCore

public struct PushPayload: Codable {
    public var userId: UserID
    public var sessionId: Int32
    public var token: Data
    public var timestamp: Timestamp

    #if os(macOS)
    public var platform: Int8 = 2
    #else
    public var platform: Int8 = 1
    #endif

    #if DEBUG
    public var sandbox = true
    #else
    public var sandbox = false
    #endif

    enum CodingKeys: String, CodingKey {
        case userId = "u"
        case sessionId = "s"
        case platform = "p"
        case token = "t"
        case sandbox = "b"
        case timestamp = "x"
    }

    public init(userId: UserID, sessionId: Int32, token: Data, timestamp: Timestamp) {
        self.userId = userId
        self.sessionId = sessionId
        self.token = token
        self.timestamp = timestamp
    }
}

extension PushPayload: ClientEventPayload {}

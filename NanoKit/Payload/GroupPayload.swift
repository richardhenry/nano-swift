//
//  GroupPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/5/24.
//

import CryptoKit
import Foundation
import NanoCore

public struct GroupPayload: Codable {
    public var groupId: GroupID
    public var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case timestamp = "x"
    }
}

extension GroupPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        try await DataStore.shared.write { db in
            try GroupModel.upsert(db, from: self)
        }
    }
}

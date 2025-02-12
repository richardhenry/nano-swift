//
//  EpochMacPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 5/25/24.
//

import Foundation
import NanoCore

public struct EpochMacPayload: Codable {
    public var groupId: GroupID
    public var epochId: EpochID
    public var userId: UserID
    public var mac: Data
    public var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case epochId = "e"
        case userId = "u"
        case mac = "m"
        case timestamp = "x"
    }
}

extension EpochMacPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        let epochMac = EpochMacModel(payload: self)

        try await DataStore.shared.write { db in
            try epochMac.save(db)
        }
    }
}

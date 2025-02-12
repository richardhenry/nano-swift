//
//  GroupActivityPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 3/1/24.
//

import Foundation
import NanoCore

public struct GroupActivityPayload: Codable {
    public var groupId: GroupID
    public var isUnread: Bool
    public var unreadCount: Int
    public var activityTimestamp: Timestamp
    public var badgeTimestamp: Timestamp?

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case isUnread = "u"
        case unreadCount = "c"
        case activityTimestamp = "x"
        case badgeTimestamp = "y"
    }
}

extension GroupActivityPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        try await DataStore.shared.write { db in
            try GroupModel.upsert(db, from: self)

            try GroupActivityModel(
                id: groupId,
                timestamp: activityTimestamp
            )
            .maybeSave(db)
        }
    }
}

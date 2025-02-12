//
//  GroupSettingPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 4/3/24.
//

import Foundation
import GRDB
import NanoCore

public struct GroupSettingPayload: Codable {
    public var userId: UserID
    public var groupId: GroupID
    public var settingType: GroupSettingType
    public var value: Int
    public var timestamp: Timestamp

    public init(
        userId: UserID,
        groupId: GroupID,
        settingType: GroupSettingType,
        value: any SettingValue,
        timestamp: Timestamp
    ) {
        self.userId = userId
        self.groupId = groupId
        self.settingType = settingType
        self.value = value.rawValue
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case userId = "u"
        case groupId = "g"
        case settingType = "k"
        case value = "v"
        case timestamp = "x"
    }
}

extension GroupSettingPayload: ClientEventPayload {}

extension GroupSettingPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        try await DataStore.shared.write { db in
            try GroupSettingModel(payload: self).save(db)
        }
    }
}

extension GroupSettingPayload: ServerErrorHandler {
    public func handleError(
        eventType: ClientEventType,
        error: ServerError
    ) async throws -> ServerError.RetryPolicy {
        if !error.shouldRetry {
            try await DataStore.shared.write { db in
                try GroupSettingModel.deleteOptimistic(db, key: [groupId, settingType])
            }
        }
        return .default
    }
}

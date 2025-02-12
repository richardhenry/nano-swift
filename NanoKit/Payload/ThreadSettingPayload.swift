//
//  ThreadSettingPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 4/3/24.
//

import Foundation
import GRDB
import NanoCore

public struct ThreadSettingPayload: Codable {
    public var userId: UserID
    public var groupId: GroupID
    public var threadId: ThreadID
    public var settingType: ThreadSettingType
    public var value: Int
    public var timestamp: Timestamp

    public init(
        userId: UserID,
        groupId: GroupID,
        threadId: ThreadID,
        settingType: ThreadSettingType,
        value: any SettingValue,
        timestamp: Timestamp
    ) {
        self.userId = userId
        self.groupId = groupId
        self.threadId = threadId
        self.settingType = settingType
        self.value = value.rawValue
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case userId = "u"
        case groupId = "g"
        case threadId = "t"
        case settingType = "k"
        case value = "v"
        case timestamp = "x"
    }
}

extension ThreadSettingPayload: ClientEventPayload {}

extension ThreadSettingPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        try await DataStore.shared.write { db in
            try ThreadSettingModel(payload: self).save(db)
        }
    }
}

extension ThreadSettingPayload: ServerErrorHandler {
    public func handleError(
        eventType: ClientEventType,
        error: ServerError
    ) async throws -> ServerError.RetryPolicy {
        if !error.shouldRetry {
            try await DataStore.shared.write { db in
                try ThreadSettingModel.deleteOptimistic(db, key: [groupId, threadId, settingType])
            }
        }

        return .default
    }
}

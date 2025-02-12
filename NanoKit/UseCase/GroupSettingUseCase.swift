//
//  GroupSettingUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/3/24.
//

import Foundation

public struct GroupSettingUseCase: UseCase {
    public var groupId: GroupID
    public var settingType: GroupSettingType
    public var value: any SettingValue
    public var dataStore: DataStore

    public init(
        groupId: GroupID,
        settingType: GroupSettingType,
        value: any SettingValue,
        dataStore: DataStore
    ) {
        self.groupId = groupId
        self.settingType = settingType
        self.value = value
        self.dataStore = dataStore
    }

    public func run() async throws {
        let session = try await dataStore.read { db in
            try SessionModel.fetchExpect(db)
        }

        let payload = GroupSettingPayload(
            userId: session.userId,
            groupId: groupId,
            settingType: settingType,
            value: value,
            timestamp: .now()
        )

        let event = try PendingEvent(eventType: .groupSettingUpdate, payload: payload)

        try await DataStore.shared.write { db in
            try GroupSettingModel(
                groupId: groupId,
                settingType: settingType,
                optimisticValue: value
            )
            .save(db)
            try event.save(db)
        }
    }
}

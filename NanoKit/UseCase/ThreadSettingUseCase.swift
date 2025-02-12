//
//  ThreadSettingUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/3/24.
//

import Foundation

public struct ThreadSettingUseCase: UseCase {
    public var groupId: GroupID
    public var threadId: ThreadID
    public var settingType: ThreadSettingType
    public var value: any SettingValue
    public var dataStore: DataStore

    public init(
        groupId: GroupID,
        threadId: ThreadID,
        settingType: ThreadSettingType,
        value: any SettingValue,
        dataStore: DataStore = .shared
    ) {
        self.groupId = groupId
        self.threadId = threadId
        self.settingType = settingType
        self.value = value
        self.dataStore = dataStore
    }

    public func run() async throws {
        let session = try await dataStore.read { db in
            try SessionModel.fetchExpect(db)
        }

        let payload = ThreadSettingPayload(
            userId: session.userId,
            groupId: groupId,
            threadId: threadId,
            settingType: settingType,
            value: value,
            timestamp: .now()
        )

        let event = try PendingEvent(eventType: .threadSettingUpdate, payload: payload)

        try await DataStore.shared.write { db in
            try ThreadSettingModel(
                groupId: groupId,
                threadId: threadId,
                settingType: settingType,
                optimisticValue: value
            )
            .save(db)
            try event.save(db)
        }
    }
}

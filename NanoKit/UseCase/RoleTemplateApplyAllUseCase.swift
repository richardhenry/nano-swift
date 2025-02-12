//
//  RoleTemplateApplyAllUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/4/24.
//

import Foundation

public struct RoleTemplateApplyAllUseCase: UseCase {
    public var groupId: GroupID
    public var dataStore: DataStore

    public init(groupId: GroupID, dataStore: DataStore) {
        self.groupId = groupId
        self.dataStore = dataStore
    }

    public func run() async throws {
        let payload = GroupPath(groupId)
        let event = try PendingEvent(eventType: .roleTemplateApplyAll, payload: payload)

        try await dataStore.write { db in
            try event.save(db)
        }

        try await event.result(expect: .ok)
    }
}

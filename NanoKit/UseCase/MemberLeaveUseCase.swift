//
//  MemberLeaveUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 3/27/24.
//

import Foundation

public struct MemberLeaveUseCase: UseCase {
    public var groupId: GroupID
    public var userId: UserID?
    public var dataStore: DataStore

    public init(groupId: GroupID, userId: UserID? = nil, dataStore: DataStore) {
        self.groupId = groupId
        self.userId = userId
        self.dataStore = dataStore
    }

    public func run() async throws {
        let userId: UserID
        if let value = self.userId {
            userId = value
        } else {
            userId = try await dataStore.read { db in
                try SessionModel.fetchExpect(db).userId
            }
        }

        let payload = MemberDeletePayload(groupId: groupId, userId: userId)
        let event = try PendingEvent(eventType: .memberDelete, payload: payload)

        try await dataStore.write { db in
            try event.save(db)
        }

        try await event.result(expect: .memberRecord)  // historic
    }
}

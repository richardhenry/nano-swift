//
//  RoleTemplateUpdateUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/4/24.
//

import Foundation

public struct RoleTemplateUpdateUseCase: UseCase {
    public enum Update {
        case addMemberPermission(MemberPermissionType)
        case removeMemberPermission(MemberPermissionType)
    }

    public var groupId: GroupID
    public var update: Update
    public var dataStore: DataStore

    public init(groupId: GroupID, update: Update, dataStore: DataStore) {
        self.groupId = groupId
        self.update = update
        self.dataStore = dataStore
    }

    public func run() async throws {
        let payload = RoleTemplateUpdatePayload(
            groupId: groupId,
            updateType: update.payloadType,
            value: update.rawValue
        )

        let event = try PendingEvent(eventType: .roleTemplateUpdate, payload: payload)

        try await dataStore.write { db in
            try event.save(db)
        }
    }
}

extension RoleTemplateUpdateUseCase.Update {
    var payloadType: RoleTemplateUpdateType {
        switch self {
        case .addMemberPermission(_):
            return .addMemberPermission
        case .removeMemberPermission(_):
            return .removeMemberPermission
        }
    }

    var rawValue: Int {
        switch self {
        case .addMemberPermission(let memberPermissionType):
            return memberPermissionType.rawValue
        case .removeMemberPermission(let memberPermissionType):
            return memberPermissionType.rawValue
        }
    }
}

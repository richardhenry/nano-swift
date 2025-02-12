//
//  RoleUpdateUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/4/24.
//

import Foundation

public struct RoleUpdateUseCase: UseCase {
    public enum Update {
        case setRoleType(RoleType)
        case addAdminPermission(AdminPermissionType)
        case removeAdminPermission(AdminPermissionType)
        case addMemberPermission(MemberPermissionType)
        case removeMemberPermission(MemberPermissionType)
    }

    public var groupId: GroupID
    public var userId: UserID
    public var update: Update
    public var dataStore: DataStore

    public init(groupId: GroupID, userId: UserID, update: Update, dataStore: DataStore = .shared) {
        self.groupId = groupId
        self.userId = userId
        self.update = update
        self.dataStore = dataStore
    }

    public func run() async throws {
        let payload = RoleUpdatePayload(
            groupId: groupId,
            userId: userId,
            updateType: update.payloadType,
            value: update.rawValue
        )

        let event = try PendingEvent(eventType: .roleUpdate, payload: payload)

        try await dataStore.write { db in
            try event.save(db)
        }
    }
}

extension RoleUpdateUseCase.Update {
    var payloadType: RoleUpdateType {
        switch self {
        case .setRoleType(_):
            return .setRoleType
        case .addAdminPermission(_):
            return .addAdminPermission
        case .removeAdminPermission(_):
            return .removeAdminPermission
        case .addMemberPermission(_):
            return .addMemberPermission
        case .removeMemberPermission(_):
            return .removeMemberPermission
        }
    }

    var rawValue: Int {
        switch self {
        case .setRoleType(let roleType):
            return roleType.rawValue
        case .addAdminPermission(let adminPermissionType):
            return adminPermissionType.rawValue
        case .removeAdminPermission(let adminPermissionType):
            return adminPermissionType.rawValue
        case .addMemberPermission(let memberPermissionType):
            return memberPermissionType.rawValue
        case .removeMemberPermission(let memberPermissionType):
            return memberPermissionType.rawValue
        }
    }
}

//
//  RolePayload.swift
//  NanoKit
//
//  Created by Richard Henry on 1/30/24.
//

import Foundation
import NanoCore

public enum RoleType: Int, Codable {
    case owner = 0
    case admin = 1
    case member = 2

    public var hasAdminPermissions: Bool {
        switch self {
        case .owner, .admin:
            return true
        case .member:
            return false
        }
    }
}

public enum AdminPermissionType: Int, Codable, CaseIterable {
    case memberPermissionUpdate = 0
    case metadataUpdate = 1
    case messageDelete = 2
    case memberBanAndEpochCreate = 3
}

public enum MemberPermissionType: Int, Codable, CaseIterable {
    case inviteCreate = 0
    case threadCreate = 1
    case messageCreate = 2
}

public struct RolePayload: Codable {
    public var groupId: GroupID
    public var userId: UserID
    public var roleType: RoleType
    public var adminPermissions: Set<AdminPermissionType>
    public var memberPermissions: Set<MemberPermissionType>
    public var inviterUserId: UserID?
    public var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case userId = "u"
        case roleType = "r"
        case adminPermissions = "a"
        case memberPermissions = "m"
        case inviterUserId = "i"
        case timestamp = "x"
    }
}

extension RolePayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        let session = try await DataStore.shared.read { db in
            try SessionModel.fetchExpect(db)
        }

        guard session.userId == userId else {
            return
        }

        try await DataStore.shared.write { db in
            try RoleModel(
                id: groupId,
                roleType: roleType,
                adminPermissions: adminPermissions,
                memberPermissions: memberPermissions
            )
            .save(db)
        }
    }
}

//
//  RoleUpdatePayload.swift
//  NanoKit
//
//  Created by Richard Henry on 4/4/24.
//

import Foundation

public enum RoleUpdateType: Int, Codable {
    case setRoleType = 0
    case addAdminPermission = 1
    case removeAdminPermission = 2
    case addMemberPermission = 3
    case removeMemberPermission = 4
}

public struct RoleUpdatePayload: Codable {
    public var groupId: GroupID
    public var userId: UserID
    public var updateType: RoleUpdateType
    public var value: Int

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case userId = "u"
        case updateType = "k"
        case value = "v"
    }
}

extension RoleUpdatePayload: ClientEventPayload {}

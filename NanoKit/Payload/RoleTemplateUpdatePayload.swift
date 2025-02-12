//
//  RoleTemplateUpdatePayload.swift
//  NanoKit
//
//  Created by Richard Henry on 2/2/24.
//

import Foundation

public enum RoleTemplateUpdateType: Int, Codable {
    case addMemberPermission = 0
    case removeMemberPermission = 1
}

public struct RoleTemplateUpdatePayload: Codable {
    public var groupId: GroupID
    public var updateType: RoleTemplateUpdateType
    public var value: Int

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case updateType = "k"
        case value = "v"
    }
}

extension RoleTemplateUpdatePayload: ClientEventPayload {}

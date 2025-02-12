//
//  RoleTemplatePayload.swift
//  NanoKit
//
//  Created by Richard Henry on 2/2/24.
//

import Foundation
import NanoCore

public struct RoleTemplatePayload: Codable {
    public var groupId: GroupID
    public var memberPermissions: Set<MemberPermissionType>
    public var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case memberPermissions = "m"
        case timestamp = "x"
    }
}

extension RoleTemplatePayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {}
}

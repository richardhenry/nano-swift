//
//  RoleModel.swift
//  NanoKit
//
//  Created by Richard Henry on 1/30/24.
//

import Foundation
import GRDB

public struct RoleModel: Codable, Identifiable, FetchableRecord, PersistableRecord, Equatable {
    public var id: GroupID
    public var roleType: RoleType
    public var adminPermissions: Set<AdminPermissionType>
    public var memberPermissions: Set<MemberPermissionType>

    public static var databaseTableName = "role"

    enum CodingKeys: String, CodingKey {
        case id = "role_group_id"
        case roleType = "role_type"
        case adminPermissions = "role_admin_permissions"
        case memberPermissions = "role_member_permissions"
    }

    @inlinable
    public static func hasPermission(
        _ db: Database,
        id: GroupID,
        adminPermission: AdminPermissionType
    ) throws -> Bool {
        try fetchOne(db, id: id)?.adminPermissions.contains(adminPermission) == true
    }

    @inlinable
    public static func hasPermission(
        _ db: Database,
        id: GroupID,
        memberPermission: MemberPermissionType
    ) throws -> Bool {
        try fetchOne(db, id: id)?.memberPermissions.contains(memberPermission) == true
    }
}

extension RoleType: DatabaseValueConvertible {}
extension AdminPermissionType: DatabaseValueConvertible {}
extension MemberPermissionType: DatabaseValueConvertible {}

//
//  ViewerRoleViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/7/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class ViewerRoleViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value: RoleModel?
    var groupId: GroupID?

    var roleType: RoleType? {
        value?.roleType
    }

    init(groupId: GroupID?) {
        self.groupId = groupId
    }

    func fetch(_ db: Database) throws -> RoleModel? {
        guard let groupId else { return nil }
        return try RoleModel.fetchOne(db, id: groupId)
    }

    func isAdminAllowed(_ adminPermissions: AdminPermissionType...) -> Bool {
        adminPermissions.allSatisfy { value?.adminPermissions.contains($0) == true }
    }

    func isMemberAllowed(_ memberPermissions: MemberPermissionType...) -> Bool {
        memberPermissions.allSatisfy { value?.memberPermissions.contains($0) == true }
    }
}

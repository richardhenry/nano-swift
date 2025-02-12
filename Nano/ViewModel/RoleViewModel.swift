//
//  RoleViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/4/24.
//

import Foundation
import NanoKit

@Observable final class RoleViewModel: AsyncViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var loadingPhase: LoadingPhase = .loading
    var groupId: GroupID
    var userId: UserID

    var roleType = RoleType.member {
        didSet { handleChange(oldValue: oldValue, newValue: roleType) }
    }

    var memberPermissionUpdate = false {
        didSet {
            handleChange(
                .memberPermissionUpdate,
                oldValue: oldValue,
                newValue: memberPermissionUpdate
            )
        }
    }

    var metadataUpdate = false {
        didSet { handleChange(.metadataUpdate, oldValue: oldValue, newValue: metadataUpdate) }
    }

    var messageDelete = false {
        didSet { handleChange(.messageDelete, oldValue: oldValue, newValue: messageDelete) }
    }

    var memberBan = false {
        didSet { handleChange(.memberBanAndEpochCreate, oldValue: oldValue, newValue: memberBan) }
    }

    var inviteCreate = false {
        didSet { handleChange(.inviteCreate, oldValue: oldValue, newValue: inviteCreate) }
    }

    var messageCreate = false {
        didSet { handleChange(.messageCreate, oldValue: oldValue, newValue: messageCreate) }
    }

    var threadCreate = false {
        didSet { handleChange(.threadCreate, oldValue: oldValue, newValue: threadCreate) }
    }

    private(set) var invitedByUser: UserModel?

    init(groupId: GroupID, userId: UserID) {
        self.groupId = groupId
        self.userId = userId
    }

    func fetch() async throws {
        let payload = MemberPath(groupId, userId)
        let event = try PendingEvent(eventType: .roleGet, payload: payload)

        try await dataStore.write { db in
            try event.save(db)
        }

        let role =
            try await event
            .result(expect: .roleRecord)
            .payload(as: RolePayload.self)

        if let userId = role.inviterUserId {
            invitedByUser = try await DataStore.shared.read { db in
                try UserModel.fetchOne(db, id: userId)
            }
        }

        roleType = role.roleType
        memberPermissionUpdate = role.adminPermissions.contains(.memberPermissionUpdate)
        metadataUpdate = role.adminPermissions.contains(.metadataUpdate)
        messageDelete = role.adminPermissions.contains(.messageDelete)
        memberBan = role.adminPermissions.contains(.memberBanAndEpochCreate)
        inviteCreate = role.memberPermissions.contains(.inviteCreate)
        threadCreate = role.memberPermissions.contains(.threadCreate)
        messageCreate = role.memberPermissions.contains(.messageCreate)
    }

    func handleChange(oldValue: RoleType, newValue: RoleType) {
        guard loadingPhase == .ready, oldValue != newValue else { return }

        RoleUpdateUseCase(groupId: groupId, userId: userId, update: .setRoleType(newValue))
            .detachedTask()
    }

    func handleChange(_ adminPermissionType: AdminPermissionType, oldValue: Bool, newValue: Bool) {
        guard loadingPhase == .ready, oldValue != newValue else { return }

        RoleUpdateUseCase(
            groupId: groupId,
            userId: userId,
            update: newValue
                ? .addAdminPermission(adminPermissionType)
                : .removeAdminPermission(adminPermissionType)
        )
        .detachedTask()
    }

    func handleChange(_ memberPermissionType: MemberPermissionType, oldValue: Bool, newValue: Bool)
    {
        guard loadingPhase == .ready, oldValue != newValue else { return }

        RoleUpdateUseCase(
            groupId: groupId,
            userId: userId,
            update: newValue
                ? .addMemberPermission(memberPermissionType)
                : .removeMemberPermission(memberPermissionType)
        )
        .detachedTask()
    }
}

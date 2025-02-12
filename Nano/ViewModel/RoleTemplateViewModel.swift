//
//  RoleTemplateViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/4/24.
//

import Foundation
import GRDB
import NanoKit
import SwiftUI

@Observable final class RoleTemplateViewModel: AsyncViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var loadingPhase: LoadingPhase = .loading
    var groupId: GroupID

    var inviteCreate = false {
        didSet { handleChange(.inviteCreate, oldValue: oldValue, newValue: inviteCreate) }
    }

    var messageCreate = false {
        didSet { handleChange(.messageCreate, oldValue: oldValue, newValue: messageCreate) }
    }

    var threadCreate = false {
        didSet { handleChange(.threadCreate, oldValue: oldValue, newValue: threadCreate) }
    }

    init(groupId: GroupID) {
        self.groupId = groupId
    }

    func fetch() async throws {
        let payload = GroupPath(groupId)
        let event = try PendingEvent(eventType: .roleTemplateGet, payload: payload)

        try await dataStore.write { db in
            try event.save(db)
        }

        let template =
            try await event
            .result(expect: .roleTemplateRecord)
            .payload(as: RoleTemplatePayload.self)

        inviteCreate = template.memberPermissions.contains(.inviteCreate)
        threadCreate = template.memberPermissions.contains(.threadCreate)
        messageCreate = template.memberPermissions.contains(.messageCreate)
    }

    func handleChange(_ memberPermissionType: MemberPermissionType, oldValue: Bool, newValue: Bool)
    {
        guard loadingPhase == .ready, oldValue != newValue else { return }

        RoleTemplateUpdateUseCase(
            groupId: groupId,
            update: newValue
                ? .addMemberPermission(memberPermissionType)
                : .removeMemberPermission(memberPermissionType),
            dataStore: dataStore
        )
        .detachedTask()
    }
}

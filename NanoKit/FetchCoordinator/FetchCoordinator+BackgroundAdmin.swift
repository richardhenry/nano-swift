//
//  FetchCoordinator+BackgroundAdmin.swift
//  NanoKit
//
//  Created by Richard Henry on 5/25/24.
//

import Combine
import Foundation
import GRDB
import NanoCore

extension FetchCoordinator {
    struct BackgroundAdmin: Fetcher, TaskDriver {
        let roleState: RoleState
        let dataStore: DataStore
        let runner = TaskRunner<GroupID>()

        func performRun(
            driverGroup group: inout ThrowingDiscardingTaskGroup<any Error>
        ) async throws {
            _ = group.addTaskUnlessCancelled {
                for await role in roleState.roleDidChange.values {
                    await handleChange(role: role)
                }
            }

            for role in roleState.roles.values {
                await handleChange(role: role)
            }
        }

        func handleChange(role: RoleModel) async {
            let canCreateEpoch = role.adminPermissions.contains(.memberBanAndEpochCreate)

            if canCreateEpoch, await runner.exists(role.id) == false {
                await start(identifier: role.id)
            } else {
                await cancel(identifier: role.id)
            }
        }

        func performStart(
            identifier: GroupID,
            localGroup group: inout ThrowingDiscardingTaskGroup<any Error>
        ) async throws {
            _ = group.addTaskUnlessCancelled {
                try await self.fetch(
                    key: FetchKey(fetchType: .virtualMember, path: identifier),
                    isPersistent: true
                )
            }

            _ = group.addTaskUnlessCancelled {
                try await self.fetch(
                    key: FetchKey(fetchType: .epochMac, path: identifier),
                    isPersistent: true
                )
            }
        }

        func didCancel(identifier: GroupID) async throws {
            try await FetchRequest.cancelPersistent(
                key: FetchKey(fetchType: .virtualMember, path: identifier)
            )

            try await FetchRequest.cancelPersistent(
                key: FetchKey(fetchType: .epochMac, path: identifier)
            )
        }
    }
}

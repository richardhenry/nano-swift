//
//  FetchCoordinator+BackgroundGroup.swift
//  NanoKit
//
//  Created by Richard Henry on 5/5/24.
//

import Combine
import Foundation
import GRDB
import NanoCore

extension FetchCoordinator {
    struct BackgroundGroup: Fetcher, TaskDriver {
        let groupState: GroupState
        let dataStore: DataStore
        let runner = TaskRunner<GroupID>()

        func performRun(
            driverGroup group: inout ThrowingDiscardingTaskGroup<any Error>
        ) async throws {
            _ = group.addTaskUnlessCancelled {
                try await self.fetch(
                    key: FetchKey(fetchType: .role),
                    isPersistent: true
                )
            }

            _ = group.addTaskUnlessCancelled {
                try await self.fetch(
                    key: FetchKey(fetchType: .metadata),
                    isPersistent: true
                )
            }

            _ = group.addTaskUnlessCancelled {
                for await groupId in groupState.groupDidBecomeActive.values {
                    await start(identifier: groupId)
                }
            }

            _ = group.addTaskUnlessCancelled {
                for await groupId in groupState.groupDidBecomeInactive.values {
                    await cancel(identifier: groupId)
                }
            }

            for groupId in groupState.activeGroups {
                await start(identifier: groupId)
            }
        }

        func performStart(
            identifier: GroupID,
            localGroup group: inout ThrowingDiscardingTaskGroup<any Error>
        ) async throws {
            _ = group.addTaskUnlessCancelled {
                try await self.fetch(
                    key: FetchKey(fetchType: .member, path: identifier),
                    isPersistent: true
                )
            }
        }

        func didCancel(identifier: GroupID) async throws {
            try await FetchRequest.cancelPersistent(
                key: FetchKey(fetchType: .member, path: identifier)
            )
        }
    }
}

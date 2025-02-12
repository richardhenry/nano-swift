//
//  FetchCoordinator+ForegroundThread.swift
//  NanoKit
//
//  Created by Richard Henry on 5/5/24.
//

import Combine
import Foundation
import GRDB

extension FetchCoordinator {
    struct ForegroundThread: Fetcher, TaskDriver {
        let visibilityState: VisibilityState
        let dataStore: DataStore
        let runner = TaskRunner<GroupID>()

        func performRun(
            driverGroup group: inout ThrowingDiscardingTaskGroup<any Error>
        ) async throws {
            for groupId in await visibilityState.visibleGroups {
                await start(identifier: groupId)
            }

            _ = group.addTaskUnlessCancelled {
                for await groupId in visibilityState.groupDidAppear.values {
                    await start(identifier: groupId)
                }
            }

            _ = group.addTaskUnlessCancelled {
                for await groupId in visibilityState.groupDidDisappear.values {
                    await cancel(identifier: groupId)
                }
            }
        }

        func performStart(
            identifier: GroupID,
            localGroup group: inout ThrowingDiscardingTaskGroup<any Error>
        ) async throws {
            _ = group.addTaskUnlessCancelled {
                try await self.fetch(
                    key: FetchKey(fetchType: .threadActivity, path: identifier),
                    isPersistent: true
                )
            }
        }

        func didCancel(identifier: GroupID) async throws {
            try await FetchRequest.cancelPersistent(
                key: FetchKey(fetchType: .threadActivity, path: identifier)
            )
        }
    }
}

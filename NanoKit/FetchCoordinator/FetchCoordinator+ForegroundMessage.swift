//
//  FetchCoordinator+ForegroundMessage.swift
//  NanoKit
//
//  Created by Richard Henry on 5/5/24.
//

import Combine
import Foundation
import GRDB

extension FetchCoordinator {
    struct ForegroundMessage: Fetcher, TaskDriver {
        let visibilityState: VisibilityState
        let dataStore: DataStore
        let runner = TaskRunner<ThreadPath>()

        func performRun(
            driverGroup group: inout ThrowingDiscardingTaskGroup<any Error>
        ) async throws {
            for threadPath in await visibilityState.visibleThreads {
                await start(identifier: threadPath)
            }

            _ = group.addTaskUnlessCancelled {
                for await threadPath in visibilityState.threadDidAppear.values {
                    await start(identifier: threadPath)
                }
            }

            _ = group.addTaskUnlessCancelled {
                for await threadPath in visibilityState.threadDidDisappear.values {
                    await cancel(identifier: threadPath)
                }
            }
        }

        func performStart(
            identifier: ThreadPath,
            localGroup group: inout ThrowingDiscardingTaskGroup<any Error>
        ) async throws {
            _ = group.addTaskUnlessCancelled {
                try await self.fetch(
                    key: FetchKey(
                        fetchType: .message,
                        path: identifier.groupId,
                        identifier.threadId
                    ),
                    isPersistent: true
                )
            }
        }

        func didCancel(identifier: ThreadPath) async throws {
            try await FetchRequest.cancelPersistent(
                key: FetchKey(
                    fetchType: .message,
                    path: identifier.groupId,
                    identifier.threadId
                )
            )
        }
    }
}

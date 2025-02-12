//
//  FetchCoordinator+BackgroundMessage.swift
//  NanoKit
//
//  Created by Richard Henry on 5/21/24.
//

import Combine
import Foundation
import GRDB
import NanoCore

extension FetchCoordinator {
    struct BackgroundMessage: Fetcher {
        let maxActivityState: MaxActivityState
        let dataStore: DataStore

        private let isDirty = CurrentValueSubject<Bool, Never>(true)

        func run() async throws {
            try await withThrowingDiscardingTaskGroup { group in
                _ = group.addTaskUnlessCancelled {
                    let iter = maxActivityState.timestamp.removeDuplicates().values

                    for await timestamp in iter {
                        log(.debug, "Received timestamp: \(timestamp)")
                        isDirty.value = true
                    }
                }

                _ = group.addTaskUnlessCancelled {
                    let iter = isDirty.removeDuplicates().filter { $0 }.values

                    for await _ in iter {
                        log(.debug, "Running...")
                        isDirty.value = false
                        try await runOnce()
                    }
                }
            }
        }

        func runOnce() async throws {
            let threadKeys = try await dataStore.read { db in
                try GroupActivityModel.fetchDirty(db)
            }

            for key in threadKeys {
                log(.debug, "Optimistically fetching threads: \(key)")

                do {
                    try await fetch(key: key, isPersistent: false)
                } catch {
                    log(error)
                }
            }

            let messageKeys = try await dataStore.read { db in
                try ThreadActivityModel.fetchDirty(db)
            }

            for key in messageKeys {
                log(.debug, "Optimistically fetching messages: \(key)")

                do {
                    try await fetch(key: key, isPersistent: false)
                } catch {
                    log(error)
                }
            }
        }
    }
}

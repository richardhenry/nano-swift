//
//  FetchCoordinator.swift
//  Nano
//
//  Created by Richard Henry on 5/2/24.
//

import Combine
import Foundation
import NanoCore

public class FetchCoordinator: Fetcher {
    public static let shared = FetchCoordinator()

    let groupState: GroupState
    let roleState: RoleState
    let maxActivityState: MaxActivityState
    let visibilityState: VisibilityState
    let dataStore: DataStore

    private var connectCancellable: AnyCancellable?
    private var taskCancellable: AnyCancellable?

    init(
        groupState: GroupState = .shared,
        roleState: RoleState = .shared,
        maxActivityState: MaxActivityState = .shared,
        visibilityState: VisibilityState = .shared,
        dataStore: DataStore = .shared
    ) {
        self.groupState = groupState
        self.roleState = roleState
        self.maxActivityState = maxActivityState
        self.visibilityState = visibilityState
        self.dataStore = dataStore

        connectCancellable = Task {
            for await _ in Sock.shared.connectSubject.values {
                taskCancellable = runCancellable()
            }
        }
        .cancellable()
    }

    func runCancellable() -> AnyCancellable {
        Task {
            do {
                try await run()
            } catch {
                log(error)
            }
        }
        .cancellable()
    }

    func run() async throws {
        try await fetch(
            key: FetchKey(fetchType: .memberRecovery),
            isPersistent: true
        )

        let epochs = try await dataStore.read { db in
            try GroupModel.fetchAll(db, isPending: false)
                .map { group in
                    EpochRangePayload(
                        oldest: try EpochModel.fetchOldestContiguous(db, groupId: group.id),
                        newest: try EpochModel.fetchCurrent(db, groupId: group.id)
                    )
                }
        }

        let payload = EpochRangeUpdatePayload(epochs: epochs)

        let event = try ClientEvent(eventType: .epochRangeUpdate, payload: payload)
        try await event.send()
        _ = try await event.result()

        try await fetch(
            key: FetchKey(fetchType: .groupActivity),
            isPersistent: true
        )

        await withDiscardingTaskGroup { group in
            _ = group.addTaskUnlessCancelled { [self] in
                do {
                    try await ForegroundThread(
                        visibilityState: visibilityState,
                        dataStore: dataStore
                    )
                    .run()
                } catch {
                    log(error)
                }
            }

            _ = group.addTaskUnlessCancelled { [self] in
                do {
                    try await ForegroundMessage(
                        visibilityState: visibilityState,
                        dataStore: dataStore
                    )
                    .run()
                } catch {
                    log(error)
                }
            }

            _ = group.addTaskUnlessCancelled { [self] in
                do {
                    try await BackgroundGroup(
                        groupState: groupState,
                        dataStore: dataStore
                    )
                    .run()
                } catch {
                    log(error)
                }
            }

            _ = group.addTaskUnlessCancelled { [self] in
                do {
                    try await BackgroundAdmin(
                        roleState: roleState,
                        dataStore: dataStore
                    )
                    .run()
                } catch {
                    log(error)
                }
            }

            _ = group.addTaskUnlessCancelled { [self] in
                do {
                    try await BackgroundMessage(
                        maxActivityState: maxActivityState,
                        dataStore: dataStore
                    )
                    .run()
                } catch {
                    log(error)
                }
            }
        }
    }
}

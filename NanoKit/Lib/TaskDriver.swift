//
//  TaskDriver.swift
//  NanoKit
//
//  Created by Richard Henry on 5/5/24.
//

import Foundation
import NanoCore

public protocol TaskDriver {
    associatedtype Identifier: Hashable
    var runner: TaskRunner<Identifier> { get }
    func performRun(driverGroup group: inout ThrowingDiscardingTaskGroup<any Error>) async throws
    func performStart(
        identifier: Identifier,
        localGroup group: inout ThrowingDiscardingTaskGroup<any Error>
    ) async throws
    func didCancel(identifier: Identifier) async throws
}

extension TaskDriver {
    public func run() async throws {
        do {
            try await withThrowingDiscardingTaskGroup { group in
                try await performRun(driverGroup: &group)
            }
        } catch {
            await runner.cancelAll()
            throw error
        }
    }

    public func start(identifier: Identifier) async {
        await runner.run(identifier) {
            Task {
                do {
                    try await withThrowingDiscardingTaskGroup { group in
                        try await performStart(identifier: identifier, localGroup: &group)
                    }
                } catch {
                    log(error)
                }
            }
            .cancellable()
        }
    }

    public func cancel(identifier: Identifier) async {
        await runner.cancel(identifier)

        do {
            try await didCancel(identifier: identifier)
        } catch {
            log(error)
        }
    }
}

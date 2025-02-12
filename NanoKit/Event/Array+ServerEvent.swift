//
//  Array+ServerEvent.swift
//  NanoKit
//
//  Created by Richard Henry on 2/28/24.
//

import Foundation
import MessagePack
import NanoCore

extension Array: ServerEventPayload where Element == ServerEvent {
    static let maxConcurrentTasks = 3

    public static func decode(from event: ServerEvent) throws -> Self {
        assert(event.eventType.payloadType is Self.Type)
        let data = try (event.data as NSData).decompressed(using: .zlib) as Data
        var array = try MessagePackDecoder().decode(self, from: data)
        if !array.isEmpty {
            array[array.endIndex - 1].requestId = event.requestId
        }
        return array
    }

    public func handle(eventType: ServerEventType) async throws {
        _ = try await handle(eventType: eventType) as [ServerEvent.Result]
    }

    public func handle(eventType: ServerEventType) async throws -> [ServerEvent.Result] {
        var results = [ServerEvent.Result]()

        switch eventType {
        case .concurrentBatch:
            await withTaskGroup(of: [ServerEvent.Result].self) { group in
                // Begin tasks up to the maximum level of concurrency.
                for idx in 0..<Swift.min(Self.maxConcurrentTasks, count) {
                    group.addTask { await handle(event: self[idx]) }
                }

                // When a task completes the next one can begin.
                var idx = Self.maxConcurrentTasks
                while idx < endIndex, await group.next() != nil {
                    let event = self[idx]
                    group.addTask { await handle(event: event) }
                    idx += 1
                }

                for await result in group {
                    results.append(contentsOf: result)
                }
            }
        case .serialBatch:
            for event in self {
                results.append(contentsOf: await handle(event: event))
            }
        default:
            assertionFailure()
        }

        return results
    }

    private func handle(event: ServerEvent) async -> [ServerEvent.Result] {
        do {
            return try await event.handle()
        } catch {
            log(.info, "Discarding event that threw an error: \(event)")
            log(error)
            return []
        }
    }
}

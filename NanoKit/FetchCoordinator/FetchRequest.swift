//
//  FetchRequest.swift
//  Nano
//
//  Created by Richard Henry on 5/2/24.
//

import Foundation
import NanoCore

struct FetchRequest {
    var key: FetchKey
    var isPersistent: Bool
    var dataStore: DataStore

    init(
        key: FetchKey,
        isPersistent: Bool,
        dataStore: DataStore
    ) {
        self.key = key
        self.isPersistent = isPersistent
        self.dataStore = dataStore
    }

    func run() async throws {
        log(.debug, "Starting: \(self)")

        try await newer()
        while try await older() {}

        do {
            try await handleCompletion()
        } catch {
            log(.warning, "Error thrown by completion handler for request: \(self)")
            log(error)
        }
    }

    func newer() async throws {
        try Task.checkCancellation()

        log(.debug, "Fetching newer: \(self)")

        let cursor = try await dataStore.read { db in
            try CursorModel.fetchOne(db, key: key)
        }

        try await fetch(
            start: nil,
            end: cursor?.start,
            isPersistent: isPersistent
        )
    }

    func older() async throws -> Bool {
        try Task.checkCancellation()

        let cursors = try await dataStore.read { db in
            try CursorModel.fetchAll(db, key: key, limit: 2)
        }

        guard let cursor = cursors.first, !cursor.isExhausted else {
            log(.debug, "Exhausted: \(self)")
            return false
        }

        log(.debug, "Fetching older: \(self)")

        try await fetch(
            start: cursors.first?.end,
            end: cursors[ifExists: 1]?.start,
            isPersistent: false
        )

        return true
    }

    func fetch(
        start: FetchIndex?,
        end: FetchIndex?,
        isPersistent: Bool
    ) async throws {
        let payload = FetchRequestPayload(
            key: key,
            start: start,
            end: end,
            isPersistent: isPersistent
        )

        let event = try ClientEvent(eventType: .fetch, payload: payload)
        try await event.send()
        _ = try await event.result(expect: .cursor)
    }

    func handleCompletion() async throws {
        switch key.fetchType {
        case .threadActivity:
            try await dataStore.write { db in
                try GroupActivityModel.completion(db, key: key)
            }
        case .message:
            try await dataStore.write { db in
                try ThreadActivityModel.completion(db, key: key)
            }
        default:
            break
        }
    }

    static func cancelPersistent(key: FetchKey) async throws {
        log(.debug, "Canceling persistent fetch: \(key)")

        let event = try ClientEvent(eventType: .cancelPersistentFetch, payload: key)
        try await event.send()
    }
}

//
//  PendingEvent.swift
//  Nano
//
//  Created by Richard Henry on 1/4/24.
//

import Combine
import Foundation
import GRDB
import MessagePack
import NanoCore

public struct PendingEvent: Codable, Identifiable, FetchableRecord, PersistableRecord {
    public var id: RequestID
    public var eventType: ClientEventType
    public var data: Data?
    public var timestamp: Timestamp

    public static var databaseTableName = "pending_event"

    enum CodingKeys: String, CodingKey {
        case id = "event_request_id"
        case eventType = "event_type"
        case data = "event_data"
        case timestamp = "event_timestamp"
    }

    public init(eventType: ClientEventType, payload: ClientEventPayload?) throws {
        log(.debug, "Event: \(eventType) - Encoding: \(payload)")
        self.id = RequestID()
        self.eventType = eventType
        if let payload {
            self.data = try MessagePackEncoder().encode(payload)
        }
        self.timestamp = .now()
    }

    public static func process(result: ServerEvent.Result) async throws {
        guard let requestId = result.event.requestId else { return }

        let pendingEvent = try await DataStore.shared.read { db in
            try PendingEvent.fetchOne(db, id: requestId)
        }

        guard let pendingEvent = pendingEvent else { return }

        let shouldRetry: Bool
        if let error = result.error {
            if let payloadType = pendingEvent.eventType.payloadType,
                payloadType is ServerErrorHandler.Type,
                let handler = try payloadType.decode(from: pendingEvent) as? ServerErrorHandler
            {
                log(.debug, "Using error handler \(type(of: handler)) for: \(requestId)")

                let retryPolicy = try await handler.handleError(
                    eventType: pendingEvent.eventType,
                    error: error
                )

                shouldRetry =
                    retryPolicy == .shouldRetry || retryPolicy == .default && error.shouldRetry
            } else {
                shouldRetry = error.shouldRetry
            }

            log(.debug, "Failed: \(requestId) Will retry: \(shouldRetry)")
        } else {
            log(.debug, "Completed: \(requestId)")
            shouldRetry = false
        }

        if !shouldRetry {
            try await DataStore.shared.write { db in
                _ = try PendingEvent.deleteOne(db, id: requestId)
            }
        }
    }

    public func aroundInsert(_ db: Database, insert: () throws -> InsertionSuccess) throws {
        _ = try insert()

        db.afterNextTransaction { _ in
            Task.detached(priority: .high) {
                guard Sock.shared.isConnected else { return }
                do {
                    try await unwrap().send()
                } catch {
                    log(error)
                }
            }
        }
    }

    public static func fetchExpectLatest(_ db: Database) throws -> Self {
        try fetchExpect(
            db,
            sql: """
                    SELECT * FROM pending_event
                    ORDER BY event_timestamp DESC
                """
        )
    }
}

extension PendingEvent: ClientEventConvertible {
    public var requestId: RequestID { id }
}

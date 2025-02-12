//
//  ThreadActivityPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 3/4/24.
//

import Foundation
import NanoCore

public struct ThreadActivityPayload: Codable {
    public var groupId: GroupID
    public var threadId: ThreadID
    public var isUnread: Bool
    public var unreadCount: Int
    public var totalCount: Int
    public var rootMessage: MessagePayload?
    public var lastMessage: MessagePayload?
    public var activityTimestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case threadId = "t"
        case isUnread = "u"
        case unreadCount = "c"
        case totalCount = "o"
        case rootMessage = "r"
        case lastMessage = "l"
        case activityTimestamp = "x"
    }
}

extension ThreadActivityPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        let root: MessageModel?
        let last: MessageModel?

        do {
            root = try await rootMessage?.load().message
        } catch {
            log(error)
            root = nil
        }

        do {
            last = try await lastMessage?.load().message
        } catch {
            log(error)
            last = nil
        }

        try await DataStore.shared.write { db in
            if let root {
                do {
                    try root.save(db)
                    try ThreadModel.upsert(db, fromMessage: root)
                } catch let error as MessageModel.SupercededError {
                    log(error)
                }
            }

            if let last {
                do {
                    try last.save(db)
                    try ThreadModel.upsert(db, fromMessage: last)
                } catch let error as MessageModel.SupercededError {
                    log(error)
                }
            }

            try ThreadActivityModel(
                groupId: groupId,
                id: threadId,
                timestamp: activityTimestamp
            )
            .maybeSave(db)

            try ThreadModel.update(db, from: self)
        }
    }
}

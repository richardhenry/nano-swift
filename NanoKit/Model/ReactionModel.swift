//
//  ReactionModel.swift
//  NanoKit
//
//  Created by Richard Henry on 5/7/24.
//

import Foundation
import GRDB
import NanoCore

public struct ReactionModel: Equatable, Codable, FetchableRecord, PersistableRecord {
    public enum SendState: Int, Codable, DatabaseValueConvertible {
        /// The reaction originated from the server.
        case sent = 0
        /// The reaction was created locally and the create event is pending.
        case pendingCreate = 1
        /// The reaction was deleted and the delete event is pending.
        case pendingDelete = 2
    }

    public var groupId: GroupID
    public var id: MessageID
    public var threadId: ThreadID
    public var userId: UserID
    public var targetId: MessageID?
    public var base: String?
    public var variation: String?
    public var sendState: SendState
    public var createTimestamp: Timestamp
    public var editTimestamp: Timestamp?

    public var display: String? {
        variation ?? base
    }

    public static var databaseTableName = "reaction"

    enum CodingKeys: String, CodingKey {
        case groupId = "reaction_group_id"
        case id = "reaction_id"
        case threadId = "reaction_thread_id"
        case userId = "reaction_user_id"
        case targetId = "reaction_target_id"
        case base = "reaction_base"
        case variation = "reaction_variation"
        case sendState = "reaction_send_state"
        case createTimestamp = "reaction_create_timestamp"
        case editTimestamp = "reaction_edit_timestamp"
    }

    public init(
        groupId: GroupID,
        id: MessageID,
        threadId: ThreadID,
        userId: UserID,
        targetId: MessageID?,
        base: String?,
        variation: String?,
        sendState: SendState,
        createTimestamp: Timestamp,
        editTimestamp: Timestamp?
    ) {
        self.groupId = groupId
        self.id = id
        self.threadId = threadId
        self.userId = userId
        self.targetId = targetId
        self.base = base
        self.variation = variation
        self.sendState = sendState
        self.createTimestamp = createTimestamp
        self.editTimestamp = editTimestamp
    }

    public init(
        sentPayload payload: MessagePayload,
        reaction: ReactionPayload?
    ) {
        assert(payload.messageType == .reaction)

        groupId = payload.groupId
        id = payload.messageId
        threadId = payload.threadId
        userId = payload.userId
        targetId = reaction?.targetId
        base = reaction?.base
        variation = reaction?.variation
        sendState = .sent
        createTimestamp = payload.createTimestamp
        editTimestamp = payload.editTimestamp
    }

    public class SupercededError: AnyError {}

    public func aroundSave(_ db: Database, save: () throws -> PersistenceSuccess) throws {
        if let existing = try Self.fetchOne(db, groupId: groupId, id: id) {
            guard existing.isSupercededBy(self) else {
                throw error(
                    "Reaction already exists or has been superceded. Group ID: \(groupId) Message ID: \(id)",
                    as: SupercededError.self,
                    logLevel: .info
                )
            }
        }

        _ = try save()

        // If this reaction previously failed to load, delete the empty message.
        try MessageModel.deleteEmpty(db, groupId: groupId, id: id)
    }

    public static func fetchAll(
        _ db: Database,
        groupId: GroupID,
        targetId: MessageID,
        userId: UserID
    ) throws -> [Self] {
        try fetchAll(
            db,
            sql: """
                    SELECT * FROM reaction
                    WHERE reaction_group_id = ?
                        AND reaction_target_id = ?
                        AND reaction_user_id = ?
                        AND reaction_base IS NOT NULL
                        AND reaction_send_state != ?
                    ORDER BY reaction_create_timestamp ASC
                """,
            arguments: [
                groupId,
                targetId,
                userId,
                ReactionModel.SendState.pendingDelete,
            ]
        )
    }

    public static func fetchOne(
        _ db: Database,
        groupId: GroupID,
        targetId: MessageID,
        userId: UserID,
        base: String
    ) throws -> Self? {
        try fetchOne(
            db,
            sql: """
                    SELECT * FROM reaction
                    WHERE reaction_group_id = ?
                        AND reaction_target_id = ?
                        AND reaction_user_id = ?
                        AND reaction_base = ?
                        AND reaction_send_state != ?
                    ORDER BY reaction_create_timestamp DESC
                """,
            arguments: [
                groupId,
                targetId,
                userId,
                base,
                ReactionModel.SendState.pendingDelete,
            ]
        )
    }

    public static func fetchOne(
        _ db: Database,
        groupId: GroupID,
        id: MessageID
    ) throws -> Self? {
        try fetchOne(
            db,
            sql: """
                    SELECT * FROM reaction
                    WHERE reaction_group_id = ?
                        AND reaction_id = ?
                """,
            arguments: [groupId, id]
        )
    }

    public static func fetchAll(
        _ db: Database,
        groupId: GroupID,
        threadId: ThreadID
    ) throws -> [Self] {
        try fetchAll(
            db,
            sql: """
                    SELECT * FROM reaction
                    WHERE reaction_group_id = ?
                        AND reaction_thread_id = ?
                        AND reaction_target_id IS NOT NULL
                        AND reaction_base IS NOT NULL
                        AND reaction_send_state != ?
                    ORDER BY reaction_create_timestamp ASC
                """,
            arguments: [
                groupId,
                threadId,
                ReactionModel.SendState.pendingDelete,
            ]
        )
    }

    public static func deleteAll(_ db: Database, groupId: GroupID) throws {
        try db.execute(
            literal: """
                    DELETE FROM reaction
                    WHERE reaction_group_id = \(groupId)
                """
        )
    }

    public static func deleteOne(_ db: Database, groupId: GroupID, id: MessageID) throws {
        try db.execute(
            literal: """
                    DELETE FROM reaction
                    WHERE reaction_group_id = \(groupId) AND reaction_id = \(id)
                """
        )
    }

    public static func setSendState(
        _ db: Database,
        groupId: GroupID,
        id: MessageID,
        newValue: SendState
    ) throws {
        try db.execute(
            literal: """
                    UPDATE reaction
                    SET reaction_send_state = \(newValue)
                    WHERE reaction_group_id = \(groupId)
                        AND reaction_id = \(id)
                """
        )
    }

    public func isSupercededBy(_ other: Self) -> Bool {
        (other.editTimestamp ?? other.createTimestamp) > (editTimestamp ?? createTimestamp)
            || other.sendState == .sent && sendState != .sent
    }
}

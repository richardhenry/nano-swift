//
//  MessageListQuery.swift
//  NanoKit
//
//  Created by Richard Henry on 4/8/24.
//

import Foundation
import GRDB

public struct MessageListQuery: Query {
    public var groupId: GroupID
    public var threadId: ThreadID

    public init(groupId: GroupID, threadId: ThreadID) {
        self.groupId = groupId
        self.threadId = threadId
    }

    public struct Item: Identifiable {
        public var id: MessageID { message.id }
        public var message: MessageModel
        public var user: UserModel?
        public var reactions: [ReactionAggregatedQuery.Item]?
    }

    public func fetch(_ db: Database) throws -> [Item] {
        let reactions = try ReactionAggregatedQuery(
            groupId: groupId,
            threadId: threadId
        )
        .fetch(db)

        return try SQLRequest<Row>(
            literal: """
                    SELECT message.*, user.*
                    FROM message

                    LEFT JOIN user
                        ON COALESCE(message_deleted_by_user_id, message_user_id) = user_id

                    WHERE message_group_id = \(groupId)
                        AND message_thread_id = \(threadId)

                    ORDER BY message_create_timestamp ASC
                """
        )
        .fetchAll(db)
        .map {
            let message = try MessageModel(row: $0)
            return Item(
                message: message,
                user: try? UserModel(row: $0),
                reactions: message.isDeleted ? nil : reactions[message.id]
            )
        }
    }
}

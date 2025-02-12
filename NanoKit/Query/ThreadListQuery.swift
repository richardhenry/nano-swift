//
//  ThreadListQuery.swift
//  NanoKit
//
//  Created by Richard Henry on 4/7/24.
//

import Foundation
import GRDB

public struct ThreadListQuery: Query {
    public var groupId: GroupID
    public var searchText: String

    public init(groupId: GroupID, searchText: String) {
        self.groupId = groupId
        self.searchText = searchText
    }

    public struct Item: Identifiable, Equatable {
        public var id: ThreadID { thread.id }
        public var thread: ThreadModel
        public var visibility: ThreadVisibilityValue
        public var message: MessageModel?
        public var user: UserModel?
    }

    public func fetch(_ db: Database) throws -> [Item] {
        var threadIds: [ThreadID]?
        if !searchText.isEmpty, let pattern = FTS5Pattern(matchingAllPrefixesIn: searchText) {
            threadIds = try ThreadID.fetchAll(
                db,
                sql: """
                        SELECT message_thread_id FROM message_search
                        WHERE message_text MATCH ?
                    """,
                arguments: [pattern]
            )
        }

        return try SQLRequest<Row>(
            literal: """
                    SELECT thread.*, message.*, user.*
                    FROM thread

                    LEFT JOIN message
                        ON thread_last_message_id = message_id
                            AND thread_group_id = message_group_id

                    LEFT JOIN user
                        ON COALESCE(message_deleted_by_user_id, message_user_id) = user_id

                    WHERE thread_group_id = \(groupId)
                        \(literal: threadIds != nil ? "AND thread_id IN \(threadIds!)" : "")
                        AND thread_total_count > 0

                    ORDER BY thread_badge_timestamp DESC
                """
        )
        .fetchAll(db)
        .map {
            let thread = try ThreadModel(row: $0)

            return Item(
                thread: thread,
                visibility: try ThreadSettingModel.fetchValue(
                    db,
                    groupId: thread.groupId,
                    threadId: thread.id,
                    settingType: .visibility,
                    defaultValue: .default
                ),
                message: try? MessageModel(row: $0),
                user: try? UserModel(row: $0)
            )
        }
    }
}

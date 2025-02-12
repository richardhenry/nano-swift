//
//  ReactionListQuery.swift
//  NanoKit
//
//  Created by Richard Henry on 4/8/24.
//

import Foundation
import GRDB

public struct ReactionListQuery: Query {
    public var groupId: GroupID
    public var targetId: MessageID

    public init(groupId: GroupID, targetId: MessageID) {
        self.groupId = groupId
        self.targetId = targetId
    }

    public struct Item: Identifiable {
        public var id: MessageID { reaction.id }
        public var reaction: ReactionModel
        public var user: UserModel?
    }

    public func fetch(_ db: Database) throws -> [Item] {
        let request = SQLRequest<Row>(
            literal: """
                    SELECT * FROM reaction
                    INNER JOIN user
                        ON reaction_user_id = user_id
                    WHERE reaction_group_id = \(groupId)
                        AND reaction_target_id = \(targetId)
                        AND reaction_base IS NOT NULL
                        AND reaction_send_state != \(ReactionModel.SendState.pendingDelete)
                    ORDER BY reaction_create_timestamp ASC
                """
        )

        return try request.fetchAll(db)
            .map {
                Item(reaction: try ReactionModel(row: $0), user: try? UserModel(row: $0))
            }
    }
}

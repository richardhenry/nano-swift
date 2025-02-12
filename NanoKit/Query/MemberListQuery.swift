//
//  MemberListQuery.swift
//  NanoKit
//
//  Created by Richard Henry on 4/7/24.
//

import Foundation
import GRDB

public struct MemberListQuery: Query {
    public var groupId: GroupID
    public var searchText: String

    public init(groupId: GroupID, searchText: String) {
        self.groupId = groupId
        self.searchText = searchText
    }

    public struct Item: Identifiable {
        public var id: UserID { member.userId }
        public var member: MemberModel
        public var user: UserModel
    }

    public func fetch(_ db: Database) throws -> [Item] {
        let pattern: FTS5Pattern?
        if !searchText.isEmpty {
            pattern = FTS5Pattern(matchingAllPrefixesIn: searchText)
        } else {
            pattern = nil
        }

        var sql: SQL = """
                SELECT member.*, user.*
                FROM member

                INNER JOIN user
                    ON member_user_id = user.user_id
            """

        if pattern != nil {
            sql += """
                    INNER JOIN user_search
                        ON user_search.user_id = user.user_id
                """
        }

        sql += """
                WHERE member_group_id = \(groupId)
                    AND member_state = \(MemberState.live)
            """

        if let pattern = pattern {
            sql += """
                    AND user_search.user_name MATCH \(pattern)
                """
        }

        sql += """
                ORDER BY member_timestamp ASC
            """

        return try SQLRequest<Row>(literal: sql).fetchAll(db)
            .map {
                Item(member: try MemberModel(row: $0), user: try UserModel(row: $0))
            }
    }
}

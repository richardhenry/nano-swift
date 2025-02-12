//
//  MentionListQuery.swift
//  NanoKit
//
//  Created by Richard Henry on 4/8/24.
//

import Foundation
import GRDB

public struct MentionListQuery: Query {
    public var groupId: GroupID
    public var searchText: String

    public init(groupId: GroupID, searchText: String) {
        self.groupId = groupId
        self.searchText = searchText
    }

    public func fetch(_ db: Database) throws -> [UserModel] {
        let session = try SessionModel.fetchExpect(db)

        let pattern: FTS5Pattern?
        if !searchText.isEmpty {
            pattern = FTS5Pattern(matchingAllPrefixesIn: searchText)
        } else {
            pattern = nil
        }

        var sql: SQL = """
                SELECT user.*
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
                    AND user.user_id != \(session.userId)
            """

        if let pattern = pattern {
            sql += """
                    AND user_search.user_name MATCH \(pattern)
                """
        }

        sql += """
                ORDER BY user.user_name ASC
            """

        return try SQLRequest<UserModel>(literal: sql).fetchAll(db)
    }
}

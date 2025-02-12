//
//  GroupListQuery.swift
//  NanoKit
//
//  Created by Richard Henry on 4/7/24.
//

import Foundation
import GRDB

public struct GroupListQuery: Query {
    public var searchText: String

    public init(searchText: String) {
        self.searchText = searchText
    }

    public func fetch(_ db: Database) throws -> [GroupModel] {
        var groupIds: [GroupID]?
        if !searchText.isEmpty, let pattern = FTS5Pattern(matchingAllPrefixesIn: searchText) {
            groupIds = try GroupID.fetchAll(
                db,
                sql: """
                        SELECT group_id FROM group_search
                        WHERE group_name MATCH ?
                    """,
                arguments: [pattern]
            )
        }

        let groups: [GroupModel]
        if let groupIds = groupIds {
            groups = try GroupModel.fetchAll(db, ids: groupIds)
        } else {
            groups = try GroupModel.fetchAll(db)
        }

        return groups.filter { !$0.isPending }
    }
}

//
//  InviteListQuery.swift
//  NanoKit
//
//  Created by Richard Henry on 4/27/24.
//

import Foundation
import GRDB

public struct InviteListQuery: Query {
    public var groupId: GroupID

    public init(groupId: GroupID) {
        self.groupId = groupId
    }

    public func fetch(_ db: Database) throws -> [InviteModel] {
        try InviteModel.fetchAll(
            db,
            sql: """
                    SELECT * FROM invite

                    -- only return invites for which there is a virtual member
                    INNER JOIN virtual_member
                        ON invite_virtual_id = virtual_member_id

                    WHERE invite_group_id = ?
                """,
            arguments: [groupId]
        )
    }
}

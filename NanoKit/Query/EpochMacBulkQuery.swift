//
//  EpochMacBulkQuery.swift
//  NanoKit
//
//  Created by Richard Henry on 5/25/24.
//

import Foundation
import GRDB

public struct EpochMacBulkQuery: Query {
    public typealias Result = [UserID: (mac: EpochMacModel, userKey: UserKeyModel?)]
    public var groupId: GroupID
    public var epochId: EpochID

    public func fetch(_ db: Database) throws -> Result {
        try SQLRequest<Row>(
            literal: """
                    SELECT epoch_mac.*, user_key.*
                    FROM epoch_mac

                    LEFT JOIN user_key
                        ON epoch_mac_user_id = user_key_id

                    WHERE epoch_mac_group_id = \(groupId)
                        AND epoch_mac_epoch_id = \(epochId)
                """
        )
        .fetchAll(db)
        .map {
            let epochMac = try EpochMacModel(row: $0)
            let userKey = try? UserKeyModel(row: $0)
            return (epochMac, userKey)
        }
        .reduce(into: Result()) { $0[$1.0.userId] = $1 }
    }
}

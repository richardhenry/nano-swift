//
//  EpochMacModel.swift
//  NanoKit
//
//  Created by Richard Henry on 5/25/24.
//

import CryptoKit
import Foundation
import GRDB
import NanoCore
import NanoCrypto

public struct EpochMacModel: Codable, FetchableRecord, PersistableRecord {
    public var groupId: GroupID
    public var epochId: EpochID
    public var userId: UserID
    public var mac: Data
    public var timestamp: Timestamp

    public static var databaseTableName: String = "epoch_mac"

    enum CodingKeys: String, CodingKey {
        case groupId = "epoch_mac_group_id"
        case epochId = "epoch_mac_epoch_id"
        case userId = "epoch_mac_user_id"
        case mac = "epoch_mac_mac"
        case timestamp = "epoch_mac_timestamp"
    }

    public init(payload: EpochMacPayload) {
        groupId = payload.groupId
        epochId = payload.epochId
        userId = payload.userId
        mac = payload.mac
        timestamp = payload.timestamp
    }

    public static func deleteAll(_ db: Database, groupId: GroupID) throws {
        try db.execute(
            sql: """
                    DELETE FROM epoch_mac
                    WHERE epoch_mac_group_id = ?
                """,
            arguments: [groupId]
        )
    }
}

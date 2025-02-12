//
//  InviteModel.swift
//  Nano
//
//  Created by Richard Henry on 1/16/24.
//

import CryptoKit
import Foundation
import GRDB
import NanoCore
import NanoCrypto

public struct InviteModel: Codable, Identifiable, FetchableRecord, PersistableRecord {
    public var id: Data { token }

    public var token: Data
    public var groupId: GroupID
    public var virtualId: VirtualMemberID
    public var isPending: Bool
    public var timestamp: Timestamp
    public var lifetime: Timestamp?

    public static var databaseTableName = "invite"

    enum CodingKeys: String, CodingKey {
        case token = "invite_token"
        case groupId = "invite_group_id"
        case virtualId = "invite_virtual_id"
        case isPending = "invite_pending"
        case timestamp = "invite_timestamp"
        case lifetime = "invite_lifetime"
    }

    public init(payload: InvitePayload, isPending: Bool) {
        token = payload.token
        groupId = payload.groupId
        virtualId = payload.virtualId
        self.isPending = isPending
        timestamp = payload.timestamp
        lifetime = payload.lifetime
    }

    public static func deleteAll(_ db: Database, groupId: GroupID) throws {
        try db.execute(
            sql: """
                    DELETE FROM invite
                    WHERE invite_group_id = ?
                """,
            arguments: [groupId]
        )
    }
}

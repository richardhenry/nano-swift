//
//  VirtualMemberModel.swift
//  NanoKit
//
//  Created by Richard Henry on 3/22/24.
//

import CryptoKit
import Foundation
import GRDB
import NanoCore
import NanoCrypto

public struct VirtualMemberModel: Codable, FetchableRecord, PersistableRecord {
    public var groupId: GroupID
    public var virtualId: VirtualMemberID
    public var ownerUserId: UserID
    public var storeKey: Curve25519.KeyAgreement.PublicKey
    public var storeKeyKyber: Kyber1024.PublicKey
    public var timestamp: Timestamp

    public static var databaseTableName = "virtual_member"

    enum CodingKeys: String, CodingKey {
        case groupId = "virtual_member_group_id"
        case virtualId = "virtual_member_id"
        case ownerUserId = "virtual_member_owner_user_id"
        case storeKey = "virtual_member_store_key"
        case storeKeyKyber = "virtual_member_store_key_kyber"
        case timestamp = "virtual_member_timestamp"
    }

    public init(payload: VirtualMemberPayload) throws {
        groupId = payload.groupId
        virtualId = payload.virtualId
        ownerUserId = payload.ownerUserId
        storeKey = payload.storeKey
        storeKeyKyber = payload.storeKeyKyber
        timestamp = payload.timestamp
    }

    public static func deleteOne(
        _ db: Database,
        groupId: GroupID,
        virtualId: VirtualMemberID
    )
        throws
    {
        try db.execute(
            sql: """
                    DELETE FROM virtual_member
                    WHERE virtual_member_group_id = ? AND virtual_member_id = ?
                """,
            arguments: [groupId, virtualId]
        )
    }

    public static func fetchAll(_ db: Database, groupId: GroupID) throws -> [VirtualMemberModel] {
        try fetchAll(
            db,
            sql: """
                    SELECT * FROM virtual_member
                    WHERE virtual_member_group_id = ?
                """,
            arguments: [groupId]
        )
    }

    public static func deleteAll(_ db: Database, groupId: GroupID) throws {
        try db.execute(
            sql: """
                    DELETE FROM virtual_member
                    WHERE virtual_member_group_id = ?
                """,
            arguments: [groupId]
        )
    }

    public static func deleteAll(_ db: Database, groupId: GroupID, ownedByUserId: UserID) throws {
        try db.execute(
            sql: """
                    DELETE FROM virtual_member
                    WHERE virtual_member_group_id = ?
                        AND virtual_member_owner_user_id = ?
                """,
            arguments: [groupId, ownedByUserId]
        )
    }
}

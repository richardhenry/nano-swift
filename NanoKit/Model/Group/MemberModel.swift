//
//  MemberModel.swift
//  Nano
//
//  Created by Richard Henry on 1/5/24.
//

import CryptoKit
import Foundation
import GRDB
import NanoCore
import NanoCrypto

public struct MemberModel: Codable, FetchableRecord, PersistableRecord {
    public var groupId: GroupID
    public var userId: UserID
    public var storeKey: Curve25519.KeyAgreement.PublicKey
    public var storeKeyKyber: Kyber1024.PublicKey
    public var authKey: Curve25519.KeyAgreement.PublicKey
    public var state: MemberState
    public var timestamp: Timestamp

    public static var databaseTableName = "member"

    enum CodingKeys: String, CodingKey {
        case groupId = "member_group_id"
        case userId = "member_user_id"
        case storeKey = "member_store_key"
        case storeKeyKyber = "member_store_key_kyber"
        case authKey = "member_auth_key"
        case state = "member_state"
        case timestamp = "member_timestamp"
    }

    public init(payload: MemberPayload) throws {
        groupId = payload.groupId
        userId = payload.userId
        storeKey = payload.storeKey
        storeKeyKyber = payload.storeKeyKyber
        authKey = payload.authKey
        state = payload.state
        timestamp = payload.timestamp
    }

    public init(
        groupId: GroupID,
        userId: UserID,
        storeKey: Curve25519.KeyAgreement.PublicKey,
        storeKeyKyber: Kyber1024.PublicKey,
        authKey: Curve25519.KeyAgreement.PublicKey,
        state: MemberState = .live,
        timestamp: Timestamp
    ) {
        self.groupId = groupId
        self.userId = userId
        self.storeKey = storeKey
        self.storeKeyKyber = storeKeyKyber
        self.authKey = authKey
        self.state = state
        self.timestamp = timestamp
    }

    public static func updateState(
        _ db: Database,
        groupId: GroupID,
        userId: UserID,
        newState: MemberState,
        timestamp: Timestamp
    ) throws {
        try db.execute(
            literal: """
                    UPDATE member
                    SET member_state = \(newState), member_timestamp = \(timestamp)
                    WHERE member_group_id = \(groupId)
                        AND member_user_id = \(userId)
                        AND member_timestamp < \(timestamp)
                """
        )
    }

    public static func fetchOne(
        _ db: Database,
        groupId: GroupID,
        userId: UserID,
        state: [MemberState]
    ) throws
        -> MemberModel?
    {
        try SQLRequest<MemberModel>(
            literal: """
                    SELECT * FROM member
                    WHERE member_group_id = \(groupId)
                        AND member_user_id = \(userId)
                        AND member_state IN \(state)
                """
        )
        .fetchOne(db)
    }

    public static func fetchOne(
        _ db: Database,
        groupId: GroupID,
        userId: UserID,
        state: MemberState
    ) throws
        -> MemberModel?
    {
        try fetchOne(db, groupId: groupId, userId: userId, state: [state])
    }

    public static func fetchExpect(
        _ db: Database,
        groupId: GroupID,
        userId: UserID,
        state: [MemberState]
    ) throws
        -> MemberModel
    {
        try fetchOne(
            db,
            groupId: groupId,
            userId: userId,
            state: state
        ) ?! error("Member not found. Group ID: \(groupId) User ID: \(userId)")
    }

    public static func fetchExpect(
        _ db: Database,
        groupId: GroupID,
        userId: UserID,
        state: MemberState
    ) throws
        -> MemberModel
    {
        try fetchExpect(db, groupId: groupId, userId: userId, state: [state])
    }

    public static func fetchAll(
        _ db: Database,
        groupId: GroupID,
        state: MemberState
    ) throws -> [MemberModel] {
        try fetchAll(
            db,
            sql: """
                    SELECT * FROM member
                    WHERE member_group_id = ? AND member_state = ?
                """,
            arguments: [groupId, state]
        )
    }

    public static func deleteAll(_ db: Database, groupId: GroupID) throws {
        try db.execute(
            sql: """
                    DELETE FROM member
                    WHERE member_group_id = ?
                """,
            arguments: [groupId]
        )
    }
}

extension MemberState: DatabaseValueConvertible {}

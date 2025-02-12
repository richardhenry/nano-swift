//
//  GroupSettingModel.swift
//  NanoKit
//
//  Created by Richard Henry on 4/3/24.
//

import Foundation
import GRDB

public enum GroupSettingType: Int, Codable, DatabaseValueConvertible {
    case notifs = 0
    case mentionNotifs = 1
    case replyNotifs = 2
    case reactionNotifs = 3
    case starOnReply = 4
}

public struct GroupSettingModel: SettingModel {
    public var groupId: GroupID
    public var settingType: GroupSettingType
    public var isOptimistic: Bool
    public var value: Int

    public static var databaseTableName: String { "group_setting" }

    public static var keyColumns: [Column] {
        [Column(CodingKeys.groupId), Column(CodingKeys.settingType)]
    }

    public static var isOptimisticColumn: Column { Column(CodingKeys.isOptimistic) }

    public var key: [any DatabaseValueConvertible] {
        [groupId, settingType]
    }

    public static var valueColumn: Column { Column(CodingKeys.value) }

    init(groupId: GroupID, settingType: GroupSettingType, optimisticValue: any SettingValue) {
        self.groupId = groupId
        self.settingType = settingType
        isOptimistic = true
        self.value = optimisticValue.rawValue
    }

    init(payload: GroupSettingPayload) {
        groupId = payload.groupId
        settingType = payload.settingType
        isOptimistic = false
        value = payload.value
    }

    public static func fetchValue<Value: SettingValue>(
        _ db: Database,
        groupId: GroupID,
        settingType: GroupSettingType,
        defaultValue: Value
    ) throws -> Value {
        try fetchValue(db, key: [groupId, settingType], defaultValue: defaultValue)
    }

    public static func fetchValue<Value: SettingValue>(
        _ db: Database,
        groupId: GroupID,
        settingType: GroupSettingType
    ) throws -> Value? {
        try fetchValue(db, key: [groupId, settingType])
    }

    public static func deleteAll(_ db: Database, groupId: GroupID) throws {
        try db.execute(
            sql: """
                    DELETE FROM group_setting
                    WHERE group_setting_group_id = ?
                """,
            arguments: [groupId]
        )
    }

    enum CodingKeys: String, CodingKey {
        case groupId = "group_setting_group_id"
        case settingType = "group_setting_type"
        case isOptimistic = "group_setting_optimistic"
        case value = "group_setting_value"
    }
}

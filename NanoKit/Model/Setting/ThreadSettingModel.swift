//
//  ThreadSettingModel.swift
//  NanoKit
//
//  Created by Richard Henry on 4/3/24.
//

import Foundation
import GRDB

public enum ThreadSettingType: Int, Codable, DatabaseValueConvertible {
    case visibility = 0
}

public struct ThreadSettingModel: SettingModel {
    public var groupId: GroupID
    public var threadId: ThreadID
    public var settingType: ThreadSettingType
    public var isOptimistic: Bool
    public var value: Int

    public static var databaseTableName: String { "thread_setting" }

    public static var keyColumns: [Column] {
        [Column(CodingKeys.groupId), Column(CodingKeys.threadId), Column(CodingKeys.settingType)]
    }

    public static var isOptimisticColumn: Column { Column(CodingKeys.isOptimistic) }

    public var key: [any DatabaseValueConvertible] {
        [groupId, threadId, settingType]
    }

    public static var valueColumn: Column { Column(CodingKeys.value) }

    init(
        groupId: GroupID,
        threadId: ThreadID,
        settingType: ThreadSettingType,
        optimisticValue: any SettingValue
    ) {
        self.groupId = groupId
        self.threadId = threadId
        self.settingType = settingType
        isOptimistic = true
        self.value = optimisticValue.rawValue
    }

    init(payload: ThreadSettingPayload) {
        groupId = payload.groupId
        threadId = payload.threadId
        settingType = payload.settingType
        isOptimistic = false
        value = payload.value
    }

    public static func fetchValue<Value: SettingValue>(
        _ db: Database,
        groupId: GroupID,
        threadId: ThreadID,
        settingType: ThreadSettingType,
        defaultValue: Value
    ) throws -> Value {
        try fetchValue(db, key: [groupId, threadId, settingType], defaultValue: defaultValue)
    }

    public static func fetchValue<Value: SettingValue>(
        _ db: Database,
        groupId: GroupID,
        threadId: ThreadID,
        settingType: ThreadSettingType
    ) throws -> Value? {
        try fetchValue(db, key: [groupId, threadId, settingType])
    }

    public static func deleteAll(_ db: Database, groupId: GroupID) throws {
        try db.execute(
            sql: """
                    DELETE FROM thread_setting
                    WHERE thread_setting_group_id = ?
                """,
            arguments: [groupId]
        )
    }

    enum CodingKeys: String, CodingKey {
        case groupId = "thread_setting_group_id"
        case threadId = "thread_setting_thread_id"
        case settingType = "thread_setting_type"
        case isOptimistic = "thread_setting_optimistic"
        case value = "thread_setting_value"
    }
}

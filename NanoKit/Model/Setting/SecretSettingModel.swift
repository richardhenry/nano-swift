//
//  SecretSettingModel.swift
//  NanoKit
//
//  Created by Richard Henry on 4/3/24.
//

import Foundation
import GRDB

public enum SecretSettingType: Int, Codable, DatabaseValueConvertible {
    case reactionSkinTone = 0
}

public struct SecretSettingModel<Value: Codable & DatabaseValueConvertible>: SettingModel {
    public var settingType: SecretSettingType
    public var isOptimistic: Bool
    public var value: Value

    public static var databaseTableName: String { "secret_setting" }

    public static var keyColumns: [Column] {
        [Column(CodingKeys.settingType)]
    }

    public static var isOptimisticColumn: Column { Column(CodingKeys.isOptimistic) }

    public var key: [any DatabaseValueConvertible] {
        [settingType]
    }

    public static var valueColumn: Column { Column(CodingKeys.value) }

    public static func fetchValue(_ db: Database, settingType: SecretSettingType) throws -> Value? {
        try fetchValue(db, key: [settingType])
    }

    enum CodingKeys: String, CodingKey {
        case settingType = "secret_setting_type"
        case isOptimistic = "secret_setting_optimistic"
        case value = "secret_setting_value"
    }
}

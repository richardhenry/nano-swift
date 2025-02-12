//
//  SettingValue.swift
//  NanoKit
//
//  Created by Richard Henry on 4/3/24.
//

import Foundation
import GRDB

public protocol SettingValue: Codable, Hashable, RawRepresentable, DatabaseValueConvertible
where RawValue == Int {}

extension Bool: SettingValue {
    public init?(rawValue: Int) {
        switch rawValue {
        case 0:
            self = false
        default:
            self = true
        }
    }

    public var rawValue: Int {
        self ? 1 : 0
    }
}

public enum GroupNotifsValue: Int, SettingValue {
    public static var `default`: Self { self.onlyStarredThreads }
    case off = 0
    case allMessages = 1
    case onlyStarredThreads = 2
}

public enum ThreadVisibilityValue: Int, SettingValue {
    case `default` = 0
    case starred = 1
    case archived = 2
}

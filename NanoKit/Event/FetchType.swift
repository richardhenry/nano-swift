//
//  FetchType.swift
//  NanoKit
//
//  Created by Richard Henry on 4/3/24.
//

import Foundation
import GRDB

public enum FetchType: Int, Codable {
    case groupActivity = 0
    case threadActivity = 1
    case message = 2
    case member = 3
    case role = 4
    case metadata = 5
    case virtualMember = 6
    case memberRecovery = 7
    case epochMac = 8
}

extension FetchType: DatabaseValueConvertible {}

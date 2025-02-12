//
//  EpochMacPartialPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 5/25/24.
//

import Foundation

public struct EpochMacPartialPayload: Codable {
    public var userId: UserID
    public var mac: Data

    enum CodingKeys: String, CodingKey {
        case userId = "u"
        case mac = "m"
    }
}

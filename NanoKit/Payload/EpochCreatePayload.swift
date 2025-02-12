//
//  EpochCreatePayload.swift
//  NanoKit
//
//  Created by Richard Henry on 3/20/24.
//

import CryptoKit
import Foundation

public struct EpochCreatePayload: Codable {
    public var epoch: EpochPayload
    public var entropy: [EntropyPayload] = []
    public var macs: [EpochMacPartialPayload] = []
    public var invalidUserIds: [UserID] = []

    enum CodingKeys: String, CodingKey {
        case epoch = "e"
        case entropy = "n"
        case macs = "m"
        case invalidUserIds = "i"
    }
}

extension EpochCreatePayload: ClientEventPayload {}

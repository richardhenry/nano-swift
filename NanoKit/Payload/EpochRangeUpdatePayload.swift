//
//  EpochRangeUpdatePayload.swift
//  NanoKit
//
//  Created by Richard Henry on 5/2/24.
//

import Foundation

public struct EpochRangeUpdatePayload: Codable {
    public var epochs: [EpochRangePayload]

    enum CodingKeys: String, CodingKey {
        case epochs = "e"
    }
}

extension EpochRangeUpdatePayload: ClientEventPayload {}

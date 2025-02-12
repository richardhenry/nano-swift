//
//  ReactionPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 5/7/24.
//

import Foundation

public struct ReactionPayload: Codable {
    public var targetId: MessageID
    public var base: String?
    public var variation: String?

    enum CodingKeys: String, CodingKey {
        case targetId = "t"
        case base = "e"
        case variation = "v"
    }
}

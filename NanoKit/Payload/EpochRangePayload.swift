//
//  EpochRangePayload.swift
//  NanoKit
//
//  Created by Richard Henry on 5/2/24.
//

import Foundation

public struct EpochRangePayload: Codable {
    public var groupId: GroupID
    /// The oldest index in the range (inclusive).
    public var start: FetchIndex
    /// The newest index in the range (inclusive).
    public var end: FetchIndex

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case start = "s"
        case end = "e"
    }

    public init(oldest: EpochModel, newest: EpochModel) {
        assert(newest.groupId == oldest.groupId)

        self.groupId = newest.groupId
        self.start = .init(timestamp: oldest.timestamp, id: oldest.id)
        self.end = .init(timestamp: newest.timestamp, id: newest.id)
    }
}

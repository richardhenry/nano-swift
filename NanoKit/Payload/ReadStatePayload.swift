//
//  ReadStatePayload.swift
//  NanoKit
//
//  Created by Richard Henry on 3/4/24.
//

import Foundation
import NanoCore

public struct ReadStatePayload: Codable {
    public var groupId: GroupID?
    public var threadId: ThreadID?
    public var timestamp: Timestamp
    public var forceUnread: Bool

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case threadId = "t"
        case timestamp = "x"
        case forceUnread = "f"
    }

    public init(groupId: GroupID?, threadId: ThreadID?, timestamp: Timestamp, forceUnread: Bool) {
        self.groupId = groupId
        self.threadId = threadId
        self.timestamp = timestamp
        self.forceUnread = forceUnread
    }
}

extension ReadStatePayload: ClientEventPayload {}

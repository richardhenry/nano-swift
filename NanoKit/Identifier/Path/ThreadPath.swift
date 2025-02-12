//
//  ThreadPath.swift
//  NanoKit
//
//  Created by Richard Henry on 5/10/24.
//

import Foundation

public struct ThreadPath: Codable, Hashable {
    public var groupId: GroupID
    public var threadId: ThreadID

    public init(_ groupId: GroupID, _ threadId: ThreadID) {
        self.groupId = groupId
        self.threadId = threadId
    }

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case threadId = "t"
    }
}

extension ThreadPath: ClientEventPayload {}

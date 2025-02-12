//
//  MessagePath.swift
//  NanoKit
//
//  Created by Richard Henry on 5/14/24.
//

import Foundation

public struct MessagePath: Codable, Hashable {
    public var groupId: GroupID
    public var messageId: MessageID

    public init(_ groupId: GroupID, _ messageId: MessageID) {
        self.groupId = groupId
        self.messageId = messageId
    }

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case messageId = "m"
    }
}

extension MessagePath: ClientEventPayload {}

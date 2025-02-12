//
//  MemberPath.swift
//  NanoKit
//
//  Created by Richard Henry on 4/4/24.
//

import Foundation

public struct MemberPath: Codable, Hashable {
    public var groupId: GroupID
    public var userId: UserID

    public init(_ groupId: GroupID, _ userId: UserID) {
        self.groupId = groupId
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case userId = "u"
    }
}

extension MemberPath: ClientEventPayload {}

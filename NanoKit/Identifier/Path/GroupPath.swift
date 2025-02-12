//
//  GroupPath.swift
//  NanoKit
//
//  Created by Richard Henry on 4/4/24.
//

import Foundation

public struct GroupPath: Codable, Hashable {
    public var groupId: GroupID

    public init(_ groupId: GroupID) {
        self.groupId = groupId
    }

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
    }
}

extension GroupPath: ClientEventPayload {}

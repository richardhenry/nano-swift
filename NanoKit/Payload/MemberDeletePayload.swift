//
//  MemberDeletePayload.swift
//  NanoKit
//
//  Created by Richard Henry on 3/27/24.
//

import Foundation

public struct MemberDeletePayload: Codable {
    public var groupId: GroupID
    public var userId: UserID

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case userId = "u"
    }
}

extension MemberDeletePayload: ClientEventPayload {}

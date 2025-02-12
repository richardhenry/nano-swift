//
//  Mention.swift
//  NanoKit
//
//  Created by Richard Henry on 2/29/24.
//

import Foundation

public struct Mention: Codable, Equatable {
    public var userId: UserID
    public var name: String
    public var location: Int  // UTF-16

    public init(userId: UserID, name: String, location: Int) {
        self.userId = userId
        self.name = name
        self.location = location
    }

    public struct Partial: Equatable {
        public var userId: UserID
        public var name: String

        public init(userId: UserID, name: String) {
            self.userId = userId
            self.name = name
        }

        public func location(_ location: Int) -> Mention {
            Mention(userId: userId, name: name, location: location)
        }
    }

    enum CodingKeys: String, CodingKey {
        case userId = "u"
        case name = "n"
        case location = "i"
    }
}

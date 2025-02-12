//
//  UserPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/15/24.
//

import Foundation
import NanoCore

public struct UserPayload: Codable {
    public var userId: UserID
    public var name: String
    public var image: String?
    public var timestamp: Timestamp

    public init(userId: UserID, name: String, image: String?, timestamp: Timestamp) {
        self.userId = userId
        self.name = name
        self.image = image
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case userId = "u"
        case name = "n"
        case image = "i"
        case timestamp = "x"
    }
}

extension UserPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        try await DataStore.shared.write { db in
            try UserModel(id: userId, name: name, image: image).save(db)
        }
    }
}

extension UserPayload: ClientEventPayload {}

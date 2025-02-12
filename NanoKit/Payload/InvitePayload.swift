//
//  InvitePayload.swift
//  Nano
//
//  Created by Richard Henry on 1/16/24.
//

import CryptoKit
import Foundation
import NanoCore

public struct InvitePayload: Codable {
    public var token: Data
    public var groupId: GroupID
    public var ownerUserId: UserID
    public var virtualId: VirtualMemberID
    public var timestamp: Timestamp
    public var lifetime: Timestamp?

    enum CodingKeys: String, CodingKey {
        case token = "t"
        case groupId = "g"
        case ownerUserId = "u"
        case virtualId = "v"
        case timestamp = "x"
        case lifetime = "l"
    }
}

extension InvitePayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        try await DataStore.shared.write { db in
            let session = try SessionModel.fetchExpect(db)
            guard session.userId == ownerUserId else {
                throw error("Handling an invite payload for another user. User ID: \(ownerUserId)")
            }
            try InviteModel(payload: self, isPending: false).save(db)
        }
    }
}

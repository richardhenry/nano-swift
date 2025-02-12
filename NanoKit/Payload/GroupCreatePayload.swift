//
//  GroupCreatePayload.swift
//  Nano
//
//  Created by Richard Henry on 1/5/24.
//

import CryptoKit
import Foundation

public struct GroupCreatePayload: Codable {
    public var group: GroupPayload
    public var member: MemberPayload
    public var epoch: EpochPayload
    public var metadata: MetadataPayload
    public var secret: SecretPayload
    public var recovery: MemberRecoveryPayload
    public var mac: Data

    enum CodingKeys: String, CodingKey {
        case group = "g"
        case member = "m"
        case epoch = "e"
        case metadata = "d"
        case secret = "s"
        case recovery = "r"
        case mac = "a"
    }
}

extension GroupCreatePayload: ClientEventPayload {}

extension GroupCreatePayload: ServerErrorHandler {
    public func handleError(
        eventType: ClientEventType,
        error: ServerError
    ) async throws -> ServerError.RetryPolicy {
        if !error.shouldRetry {
            try await DataStore.shared.write { db in
                try GroupModel.deleteOne(db, id: group.groupId)
                try EpochModel.deleteAll(db, groupId: group.groupId)
                try MetadataModel.deleteOne(db, id: group.groupId)
            }
        }
        return .default
    }
}

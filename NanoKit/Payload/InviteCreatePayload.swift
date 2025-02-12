//
//  InviteCreatePayload.swift
//  Nano
//
//  Created by Richard Henry on 1/16/24.
//

import CryptoKit
import Foundation
import NanoCrypto

public struct InviteCreatePayload: Codable {
    public var invite: InvitePayload
    public var virtualMember: VirtualMemberPayload
    public var secret: SecretPayload

    enum CodingKeys: String, CodingKey {
        case invite = "i"
        case virtualMember = "v"
        case secret = "s"
    }
}

extension InviteCreatePayload: ClientEventPayload {}

extension InviteCreatePayload: ServerErrorHandler {
    public func handleError(
        eventType: ClientEventType,
        error: ServerError
    ) async throws -> ServerError.RetryPolicy {
        if !error.shouldRetry {
            try await DataStore.shared.write { db in
                try InviteModel.deleteOne(db, id: invite.token)
                try VirtualMemberModel.deleteOne(
                    db,
                    groupId: virtualMember.groupId,
                    virtualId: virtualMember.virtualId
                )
            }
        }
        return .default
    }
}

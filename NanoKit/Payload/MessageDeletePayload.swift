//
//  MessageDeletePayload.swift
//  NanoKit
//
//  Created by Richard Henry on 5/14/24.
//

import CryptoKit
import Foundation
import NanoCore

public struct MessageDeletePayload: Codable {
    public var groupId: GroupID
    public var messageId: MessageID
    public var messageType: MessageType
    public var signature: Data

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case messageId = "m"
        case messageType = "y"
        case signature = "s"
    }

    public init(
        deleting value: MessagePayloadConvertible,
        deletedByUserId userId: UserID,
        signingKey: Curve25519.Signing.PrivateKey
    ) throws {
        groupId = value.groupId
        messageId = value.id
        messageType = value.messageType

        let signedData = MessagePayload.signedData(
            groupId: groupId,
            messageId: messageId,
            epochId: nil,
            threadId: value.threadId,
            userId: value.userId,
            deletedByUserId: userId,
            ciphertext: nil
        )

        signature = try signingKey.signature(for: signedData)
    }
}

extension MessageDeletePayload: ClientEventPayload, ServerErrorHandler {
    public func handleError(
        eventType: ClientEventType,
        error: ServerError
    ) async throws -> ServerError.RetryPolicy {
        switch messageType {
        case .message:
            return .shouldNotRetry

        case .reaction:
            if !error.shouldRetry {
                try await DataStore.shared.write { db in
                    try ReactionModel.setSendState(
                        db,
                        groupId: groupId,
                        id: messageId,
                        newValue: .sent
                    )
                }

                return .shouldNotRetry
            } else {
                return .shouldRetry
            }
        }
    }
}

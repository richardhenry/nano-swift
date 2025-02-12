//
//  MessageUpdatePayload.swift
//  NanoKit
//
//  Created by Richard Henry on 5/10/24.
//

import CryptoKit
import Foundation
import MessagePack
import NanoCore
import NanoCrypto

public struct MessageUpdatePayload: Codable {
    public var groupId: GroupID
    public var messageId: MessageID
    public var epochId: EpochID
    public var threadId: ThreadID
    public var messageType: MessageType
    public var ciphertext: XChaChaPoly.SealedBox
    public var signature: Data

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case messageId = "m"
        case epochId = "e"
        case threadId = "t"
        case messageType = "p"
        case ciphertext = "c"
        case signature = "s"
    }

    public init(
        encrypting value: MessagePayloadConvertible,
        inEpoch epoch: EpochModel,
        senderUserId userId: UserID,
        signingKey: Curve25519.Signing.PrivateKey
    ) throws {
        groupId = value.groupId
        messageId = value.id
        epochId = epoch.id
        threadId = value.threadId
        messageType = value.messageType

        guard epoch.groupId == value.groupId else {
            throw error("Provided epoch does not match.")
        }

        let content: MessagePayload.Content

        switch value {
        case .message(let message):
            content = MessagePayload.Content(
                text: message.text,
                mentions: message.mentions,
                attachments: message.attachments,
                links: message.links
            )
        case .reaction(let reaction):
            guard let targetId = reaction.targetId, let base = reaction.base else {
                throw error("Update payload should not be created with a deleted reaction.")
            }

            content = MessagePayload.Content(
                reaction: .init(
                    targetId: targetId,
                    base: base,
                    variation: reaction.variation
                )
            )
        }

        let encoded = try MessagePackEncoder().encode(content)
        let padded = try Padme.pad(originalData: encoded)

        let messageKey = try MessagePayload.deriveMessageKey(epoch: epoch, threadId: threadId)
        ciphertext = try XChaChaPoly.seal(padded, using: messageKey)

        let signedData = MessagePayload.signedData(
            groupId: groupId,
            messageId: messageId,
            epochId: epochId,
            threadId: threadId,
            userId: userId,
            deletedByUserId: nil,
            ciphertext: ciphertext
        )

        signature = try signingKey.signature(for: signedData)
    }
}

extension MessageUpdatePayload: ClientEventPayload, ServerErrorHandler {
    public func handleError(
        eventType: ClientEventType,
        error: ServerError
    ) async throws -> ServerError.RetryPolicy {
        switch messageType {
        case .message:
            if eventType == .messageCreate {
                try await DataStore.shared.write { db in
                    try MessageModel.setSendState(
                        db,
                        groupId: groupId,
                        id: messageId,
                        newValue: .failed
                    )
                }
            }

            return .shouldNotRetry

        case .reaction:
            if !error.shouldRetry {
                switch eventType {
                case .messageCreate:
                    try await DataStore.shared.write { db in
                        try ReactionModel.deleteOne(
                            db,
                            groupId: groupId,
                            id: messageId
                        )
                    }
                default:
                    break
                }

                return .shouldNotRetry
            } else {
                return .shouldRetry
            }
        }
    }
}

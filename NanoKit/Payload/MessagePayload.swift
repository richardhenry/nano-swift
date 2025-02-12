//
//  MessagePayload.swift
//  Nano
//
//  Created by Richard Henry on 1/4/24.
//

import CryptoKit
import Foundation
import GRDB
import MessagePack
import NanoCore
import NanoCrypto
import UniformTypeIdentifiers

public enum MessageType: Int, Codable, DatabaseValueConvertible {
    case message = 0
    case reaction = 1
}

public struct MessagePayload: Codable, SignedPayload {
    public var groupId: GroupID
    public var messageId: MessageID
    public var epochId: EpochID?
    public var threadId: ThreadID
    public var userId: UserID
    public var deletedByUserId: UserID?
    public var isRoot: Bool
    public var messageType: MessageType
    public var ciphertext: XChaChaPoly.SealedBox?
    public var signature: Data
    public var createTimestamp: Timestamp
    public var editTimestamp: Timestamp?

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case messageId = "m"
        case epochId = "e"
        case threadId = "t"
        case userId = "u"
        case deletedByUserId = "d"
        case isRoot = "r"
        case messageType = "p"
        case ciphertext = "c"
        case signature = "s"
        case createTimestamp = "x"
        case editTimestamp = "y"
    }

    public struct Content: Codable {
        public var text: String?
        public var mentions: [Mention]?
        public var attachments: [EncryptedAttachment]?
        public var links: [LinkPreview]?
        public var reaction: ReactionPayload?

        enum CodingKeys: String, CodingKey {
            case text = "t"
            case mentions = "m"
            case attachments = "a"
            case links = "i"
            case reaction = "c"
        }
    }

    public var signedData: Data {
        Self.signedData(
            groupId: groupId,
            messageId: messageId,
            epochId: epochId,
            threadId: threadId,
            userId: userId,
            deletedByUserId: deletedByUserId,
            ciphertext: ciphertext
        )
    }

    public var signingUserId: UserID {
        deletedByUserId ?? userId
    }

    public var timestamp: Timestamp {
        editTimestamp ?? createTimestamp
    }

    public static func signedData(
        groupId: GroupID,
        messageId: MessageID,
        epochId: EpochID?,
        threadId: ThreadID,
        userId: UserID,
        deletedByUserId: UserID?,
        ciphertext: XChaChaPoly.SealedBox?
    ) -> Data {
        var out = Data(useCaseByte: .messageSignature)
        out.append(groupId.data)
        out.append(messageId.data)

        if let epochId {
            out.append(epochId.data)
        } else {
            out.append(EpochID.zero.data)
        }

        out.append(threadId.data)
        out.append(userId.data)

        if let deletedByUserId {
            out.append(deletedByUserId.data)
        } else {
            out.append(UserID.zero.data)
        }

        if let ciphertext {
            out.append(ciphertext.combined)
        }

        return out
    }

    public func load(
        dataStore: DataStore = .shared,
        messageKey: SymmetricKey? = nil
    ) async throws -> MessagePayloadConvertible {
        let (epoch, userKey) = try await dataStore.read { db in
            try fetchDeps(db)
        }

        try validateSignature(with: userKey)

        if let epoch {
            let messageKey =
                try messageKey ?? Self.deriveMessageKey(epoch: epoch, threadId: threadId)

            return try decrypt(
                epoch: epoch,
                userKey: userKey,
                messageKey: messageKey
            )
        } else {
            switch messageType {
            case .message:
                return .message(MessageModel(sentPayload: self, content: nil))
            case .reaction:
                return .reaction(ReactionModel(sentPayload: self, reaction: nil))
            }
        }
    }

    func fetchDeps(_ db: Database) throws -> (epoch: EpochModel?, userKey: UserKeyModel) {
        let epoch: EpochModel?

        if let epochId {
            epoch = try EpochModel.fetchExpect(db, groupId: groupId, id: epochId)
        } else {
            epoch = nil
        }

        let userKey = try UserKeyModel.fetchExpect(db, id: signingUserId)

        return (epoch, userKey)
    }

    func decrypt(
        epoch: EpochModel,
        userKey: UserKeyModel,
        messageKey: SymmetricKey
    ) throws -> MessagePayloadConvertible {
        guard epoch.id == epochId else {
            throw error("Provided epoch does not match.")
        }

        guard let ciphertext else {
            throw error("Message does not contain ciphertext to decrypt: \(self)")
        }

        let padded = try XChaChaPoly.open(ciphertext, using: messageKey)
        let plaintext = try Padme.unpad(paddedData: padded)
        let content = try MessagePackDecoder().decode(Content.self, from: plaintext)

        switch messageType {
        case .message:
            return .message(MessageModel(sentPayload: self, content: content))
        case .reaction:
            return .reaction(ReactionModel(sentPayload: self, reaction: content.reaction))
        }
    }

    static func deriveMessageKey(
        epoch: EpochModel,
        threadId: ThreadID
    ) throws -> SymmetricKey {
        let rootKey: SymmetricKey = try KeychainStorage.shared.get(
            .epochRootKey(epoch.id)
        )

        return HKDF<SHA256>
            .deriveKey(
                inputKeyMaterial: rootKey,
                info: Data(
                    "message_epoch_\(epoch.sequenceId)_cipher_v1_\(epoch.groupId.data.base64EncodedString())_\(threadId.data.base64EncodedString())"
                        .utf8
                ),
                outputByteCount: 32
            )
    }
}

extension MessagePayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        let value: MessagePayloadConvertible

        do {
            value = try await load()
        } catch {
            log(.warning, "Message failed to load. Group ID: \(groupId) Message ID: \(messageId)")
            log(error)

            let empty = MessageModel(emptyFromPayload: self)
            try await DataStore.shared.write { db in
                try empty.save(db)
            }

            return
        }

        try await DataStore.shared.write { db in
            switch value {
            case .message(let message):
                try message.save(db)
            case .reaction(let reaction):
                try reaction.save(db)
            }
        }
    }
}

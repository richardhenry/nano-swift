//
//  MetadataPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/22/24.
//

import CryptoKit
import Foundation
import MessagePack
import NanoCore
import NanoCrypto

public struct MetadataPayload: Codable, SignedPayload {
    public var groupId: GroupID
    public var ciphertext: XChaChaPoly.SealedBox
    public var epochId: EpochID
    public var editorUserId: UserID
    public var signature: Data
    public var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case ciphertext = "c"
        case epochId = "e"
        case editorUserId = "u"
        case signature = "s"
        case timestamp = "x"
    }

    public var signedData: Data {
        var out = Data(useCaseByte: .metadataSignature)
        out.append(groupId.data)
        out.append(ciphertext.combined)
        out.append(epochId.data)
        out.append(editorUserId.data)
        return out
    }

    public var signingUserId: UserID {
        editorUserId
    }

    public struct Content: Codable {
        public var name: String
        public var image: EncryptedAttachment?
        public var emoji: String?

        enum CodingKeys: String, CodingKey {
            case name = "n"
            case image = "i"
            case emoji = "e"
        }
    }

    public init(
        groupId: GroupID,
        encrypting content: Content,
        inEpoch epoch: EpochModel,
        epochRootKey: SymmetricKey,
        userId: UserID,
        signingKey: Curve25519.Signing.PrivateKey
    ) throws {
        guard epoch.groupId == groupId else {
            throw error("Provided epoch is for the wrong group.")
        }

        self.groupId = groupId
        self.epochId = epoch.id
        self.editorUserId = userId
        self.timestamp = .now()

        let encoded = try MessagePackEncoder().encode(content)

        let padded = try Padme.pad(originalData: encoded)

        let metadataKey = try Self.deriveMetadataKey(epochId: epoch.id, epochRootKey: epochRootKey)
        ciphertext = try XChaChaPoly.seal(padded, using: metadataKey)

        signature = Data()
        signature = try signingKey.signature(for: signedData)
    }

    public func decrypt(metadataKey: SymmetricKey) throws -> Content {
        let padded = try XChaChaPoly.open(ciphertext, using: metadataKey)
        let encoded = try Padme.unpad(paddedData: padded)
        return try MessagePackDecoder().decode(Content.self, from: encoded)
    }

    public static func deriveMetadataKey(
        epochId: EpochID,
        epochRootKey: SymmetricKey
    ) throws
        -> SymmetricKey
    {
        return HKDF<SHA256>
            .deriveKey(
                inputKeyMaterial: epochRootKey,
                info: Data("metadata_epoch_\(epochId.base64EncodedString)".utf8),
                outputByteCount: 32
            )
    }
}

extension MetadataPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        let (epoch, userKey) = try await DataStore.shared.read { db in
            let epoch = try EpochModel.fetchExpect(db, groupId: groupId, id: epochId)
            let userKey = try UserKeyModel.fetchExpect(db, id: editorUserId)
            return (epoch, userKey)
        }

        try validateSignature(with: userKey)

        let rootKey =
            try KeychainStorage.shared.get(.epochRootKey(epoch.id)) as SymmetricKey
        let metadataKey = try Self.deriveMetadataKey(epochId: epoch.id, epochRootKey: rootKey)
        let content = try decrypt(metadataKey: metadataKey)

        try await DataStore.shared.write { db in
            try GroupModel.upsert(db, id: groupId, from: content)
            try MetadataModel(id: groupId, epochId: epochId).save(db)
        }
    }
}

extension MetadataPayload: ClientEventPayload {}

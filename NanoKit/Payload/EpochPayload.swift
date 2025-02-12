//
//  EpochPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/16/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public struct EpochPayload: Codable, SignedPayload {
    public var groupId: GroupID
    public var epochId: EpochID
    public var sequenceId: UInt32
    public var creatorUserId: UserID
    public var previousEpoch: PreviousEpoch?
    public var signature: Data
    public var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case epochId = "e"
        case sequenceId = "s"
        case creatorUserId = "u"
        case previousEpoch = "p"
        case signature = "i"
        case timestamp = "x"
    }

    public struct PreviousEpoch: Codable {
        public var epochId: EpochID
        public var ciphertext: XChaChaPoly.SealedBox

        enum CodingKeys: String, CodingKey {
            case epochId = "e"
            case ciphertext = "c"
        }
    }

    public var signedData: Data {
        var out = Data(useCaseByte: .epochSignature)
        out.append(groupId.data)
        out.append(epochId.data)

        var sequenceId = sequenceId.bigEndian
        out.append(Data(bytes: &sequenceId, count: MemoryLayout.size(ofValue: sequenceId)))

        if let previousEpoch {
            out.append(previousEpoch.epochId.data)
            out.append(previousEpoch.ciphertext.combined)
        } else {
            out.append(EpochID.zero.data)
        }

        out.append(creatorUserId.data)
        return out
    }

    public var signingUserId: UserID {
        creatorUserId
    }

    public init(
        groupId: GroupID,
        epochId: EpochID,
        sequenceId: UInt32,
        creatorUserId: UserID,
        previousEpoch: PreviousEpoch?,
        timestamp: Timestamp,
        signingKey: Curve25519.Signing.PrivateKey
    ) throws {
        self.groupId = groupId
        self.epochId = epochId
        self.sequenceId = sequenceId
        self.creatorUserId = creatorUserId
        self.previousEpoch = previousEpoch
        self.timestamp = timestamp

        signature = Data()
        signature = try signingKey.signature(for: signedData)
    }
}

// MARK: Previous Epoch

extension EpochPayload.PreviousEpoch {
    public init(
        previousEpochId: EpochID,
        encryptingPrevRootKey prevRootKey: SymmetricKey,
        fromNextRootKey nextRootKey: SymmetricKey
    ) throws {
        epochId = previousEpochId

        let metadataKey = Self.deriveMetadataKey(
            nextRootKey: nextRootKey,
            previousEpochId: previousEpochId
        )

        ciphertext = try prevRootKey.withUnsafeBytes { bytes in
            try XChaChaPoly.seal(
                bytes,
                using: metadataKey,
                authenticating: Data("epoch_secrets_\(previousEpochId.base64EncodedString)".utf8)
            )
        }
    }

    public func decryptRootKey(nextRootKey: SymmetricKey) throws -> SymmetricKey {
        let metadataKey = Self.deriveMetadataKey(nextRootKey: nextRootKey, previousEpochId: epochId)

        return
            try XChaChaPoly.open(
                ciphertext,
                using: metadataKey,
                authenticating: Data("epoch_secrets_\(epochId.base64EncodedString)".utf8),
                intoSecureMemory: true
            )
            .withUnsafeBytes { SymmetricKey(data: $0) }
    }

    public static func deriveMetadataKey(
        nextRootKey: SymmetricKey,
        previousEpochId: EpochID
    )
        -> SymmetricKey
    {
        HKDF<SHA256>
            .deriveKey(
                inputKeyMaterial: nextRootKey,
                info: Data("epoch_secrets_key_\(previousEpochId.base64EncodedString)".utf8),
                outputByteCount: 32
            )
    }
}

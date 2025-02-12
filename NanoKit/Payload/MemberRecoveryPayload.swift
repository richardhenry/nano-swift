//
//  MemberRecoveryPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 4/25/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public struct MemberRecoveryPayload: Codable {
    public var groupId: GroupID
    public var userId: UserID
    public var epochId: EpochID
    public var metadataEpochId: EpochID
    public var ciphertext: XChaChaPoly.SealedBox
    public var senderSessionId: Int32
    public var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case userId = "u"
        case epochId = "e"
        case metadataEpochId = "m"
        case ciphertext = "c"
        case senderSessionId = "d"
        case timestamp = "x"
    }

    public init(
        groupId: GroupID,
        userId: UserID,
        epochId: EpochID,
        metadataEpochId: EpochID,
        encrypting secrets: Secrets,
        recoveryKey: SymmetricKey,
        senderSessionId: Int32,
        timestamp: Timestamp
    ) throws {
        self.groupId = groupId
        self.userId = userId
        self.epochId = epochId
        self.metadataEpochId = metadataEpochId
        self.ciphertext = try secrets.encrypt(
            groupId: groupId,
            userId: userId,
            recoveryKey: recoveryKey
        )
        self.senderSessionId = senderSessionId
        self.timestamp = timestamp
    }
}

// MARK: Secrets

extension MemberRecoveryPayload {
    public struct Secrets {
        public var epochRootKey: SymmetricKey
        public var metadataEpochRootKey: SymmetricKey

        public func encrypt(
            groupId: GroupID,
            userId: UserID,
            recoveryKey: SymmetricKey
        ) throws
            -> XChaChaPoly.SealedBox
        {
            let data = try SecureBytePack([
                epochRootKey,
                metadataEpochRootKey,
            ])
            .pack()

            let secretKey = MemberRecoveryPayload.deriveSecretKey(
                recoveryKey: recoveryKey,
                groupId: groupId,
                userId: userId
            )

            return try XChaChaPoly.seal(
                data,
                using: secretKey,
                authenticating: MemberRecoveryPayload.authenticatedData(
                    groupId: groupId,
                    userId: userId
                )
            )
        }
    }

    public func decryptSecrets(recoveryKey: SymmetricKey) throws -> Secrets {
        let secretKey = Self.deriveSecretKey(
            recoveryKey: recoveryKey,
            groupId: groupId,
            userId: userId
        )

        let data = try XChaChaPoly.open(
            ciphertext,
            using: secretKey,
            authenticating: Self.authenticatedData(
                groupId: groupId,
                userId: userId
            ),
            intoSecureMemory: true
        )

        let pack = try SecureBytePack(
            from: data,
            layout: [
                .item(SymmetricKey.self, sizeBytes: 32),
                .item(SymmetricKey.self, sizeBytes: 32),
            ]
        )

        return Secrets(
            epochRootKey: try pack.item(at: 0),
            metadataEpochRootKey: try pack.item(at: 1)
        )
    }

    static func authenticatedData(groupId: GroupID, userId: UserID) -> Data {
        Data(
            "member_recovery_secrets_\(groupId.base64EncodedString)_\(userId.base64EncodedString)"
                .utf8
        )
    }

    static func deriveSecretKey(
        recoveryKey: SymmetricKey,
        groupId: GroupID,
        userId: UserID
    ) -> SymmetricKey {
        HKDF<SHA256>
            .deriveKey(
                inputKeyMaterial: recoveryKey,
                info: Data(
                    "member_recovery_secrets_key_\(groupId.base64EncodedString)_\(userId.base64EncodedString)"
                        .utf8
                ),
                outputByteCount: 32
            )
    }
}

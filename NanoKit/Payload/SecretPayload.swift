//
//  SecretPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 4/23/24.
//

import CryptoKit
import Foundation
import MessagePack
import NanoCore
import NanoCrypto

public enum SecretType: Int, Codable {
    case recoveryKey = 0
    case userSigningKey = 1
    case memberKey = 2
    case inviteSecretKey = 3
}

public struct SecretPayload: Codable {
    public var secretId: SecretID
    public var secretType: SecretType
    public var objectId: AnyID?
    public var ciphertext: ChaChaPolyIETF.SealedBox
    public var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case secretId = "s"
        case secretType = "y"
        case objectId = "k"
        case ciphertext = "c"
        case timestamp = "x"
    }

    init<Secret: DataProtocol>(
        secretType: SecretType,
        objectId: (any UniqueIdentifier)?,
        encrypting secret: Secret,
        usingRecoveryKey recoveryKey: SymmetricKey,
        timestamp: Timestamp
    ) throws {
        secretId = SecretID()
        self.secretType = secretType
        self.objectId = objectId?.eraseToAny()
        self.timestamp = timestamp

        let secretKey = Self.deriveSecretKey(
            recoveryKey: recoveryKey,
            secretId: secretId
        )

        self.ciphertext = try ChaChaPolyIETF.seal(
            secret,
            using: secretKey,
            authenticating: Data("secret_\(secretId.base64EncodedString)".utf8)
        )
    }

    func decryptSecret(recoveryKey: SymmetricKey) throws -> Data {
        let secretKey = Self.deriveSecretKey(
            recoveryKey: recoveryKey,
            secretId: secretId
        )

        return try ChaChaPolyIETF.open(
            ciphertext,
            using: secretKey,
            authenticating: Data("secret_\(secretId.base64EncodedString)".utf8),
            intoSecureMemory: true
        )
    }

    static func deriveSecretKey(recoveryKey: SymmetricKey, secretId: SecretID) -> SymmetricKey {
        HKDF<SHA256>
            .deriveKey(
                inputKeyMaterial: recoveryKey,
                info: Data("secret_key_\(secretId.base64EncodedString)".utf8),
                outputByteCount: 32
            )
    }
}

extension SecretPayload: ClientEventPayload {}

extension SecretPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        let userId = try await DataStore.shared.read { db in
            try SessionModel.fetchExpect(db).userId
        }

        try await SecretSaveUseCase(userId: userId, secret: self).run()
    }
}

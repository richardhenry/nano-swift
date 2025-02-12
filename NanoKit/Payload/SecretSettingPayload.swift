//
//  SecretSettingPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 4/3/24.
//

import CryptoKit
import Foundation
import GRDB
import MessagePack
import NanoCore
import NanoCrypto

public struct SecretSettingPayload: Codable {
    public var userId: UserID
    public var settingType: SecretSettingType
    public var ciphertext: XChaChaPoly.SealedBox
    public var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case userId = "u"
        case settingType = "k"
        case ciphertext = "v"
        case timestamp = "x"
    }

    public init(
        userId: UserID,
        settingType: SecretSettingType,
        encrypting value: Encodable,
        usingRecoveryKey recoveryKey: SymmetricKey,
        timestamp: Timestamp
    ) throws {
        self.userId = userId
        self.settingType = settingType
        self.timestamp = timestamp

        let secretSettingKey = Self.deriveSecretSettingKey(recoveryKey: recoveryKey)
        let encoded = try MessagePackEncoder().encode(value)
        let padded = try Padme.pad(originalData: encoded)
        ciphertext = try XChaChaPoly.seal(
            padded,
            using: secretSettingKey,
            authenticating: settingType.tag
        )
    }

    public func decryptValue<T: Decodable>(recoveryKey: SymmetricKey) throws -> T {
        let secretSettingKey = Self.deriveSecretSettingKey(recoveryKey: recoveryKey)
        let padded = try XChaChaPoly.open(
            ciphertext,
            using: secretSettingKey,
            authenticating: settingType.tag
        )
        let encoded = try Padme.unpad(paddedData: padded)
        return try MessagePackDecoder().decode(T.self, from: encoded)
    }

    static func deriveSecretSettingKey(recoveryKey: SymmetricKey) -> SymmetricKey {
        HKDF<SHA256>
            .deriveKey(
                inputKeyMaterial: recoveryKey,
                info: Data("user_secret_setting_key".utf8),
                outputByteCount: 32
            )
    }
}

extension SecretSettingType {
    var tag: Data {
        Data("user_secret_setting_\(rawValue)".utf8)
    }
}

extension SecretSettingPayload: ClientEventPayload {}

extension SecretSettingPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        let session = try await DataStore.shared.read { db in
            try SessionModel.fetchExpect(db)
        }

        let recoveryKey: SymmetricKey = try KeychainStorage.shared.get(
            .recoveryKey(session.userId)
        )

        switch settingType {
        case .reactionSkinTone:
            let value: Int? = try decryptValue(recoveryKey: recoveryKey)

            let setting = SecretSettingModel(
                settingType: settingType,
                isOptimistic: false,
                value: value
            )

            try await DataStore.shared.write { db in
                try setting.save(db)
            }
        }
    }
}

extension SecretSettingPayload: ServerErrorHandler {
    public func handleError(
        eventType: ClientEventType,
        error: ServerError
    ) async throws -> ServerError.RetryPolicy {
        if !error.shouldRetry {
            try await DataStore.shared.write { db in
                switch settingType {
                case .reactionSkinTone:
                    try SecretSettingModel<Int?>.deleteOptimistic(db, key: [settingType])
                }
            }
        }
        return .default
    }
}

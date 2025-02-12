//
//  RegisterNewUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/7/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public struct RegisterNewUseCase: UseCase {
    public var token: CheckByteToken
    public var user: UserPayload
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        token: CheckByteToken,
        user: UserPayload,
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.token = token
        self.user = user
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        let ephemeralRecoveryKey = SymmetricKey(size: .bits256)
        try keychainStorage.save(ephemeralRecoveryKey, to: .ephemeralRecoveryKey(user.userId))

        let recoveryKey = SymmetricKey(size: .bits256)
        try keychainStorage.save(recoveryKey, to: .recoveryKey(user.userId))

        let signingKey = Curve25519.Signing.PrivateKey()

        var localUserKey = UserKeyModel(
            id: user.userId,
            signing: signingKey.publicKey,
            timestamp: user.timestamp
        )

        let recoverySecret = try recoveryKey.withUnsafeBytes { bytes in
            try SecretPayload(
                secretType: .recoveryKey,
                objectId: nil,
                encrypting: bytes,
                usingRecoveryKey: ephemeralRecoveryKey,
                timestamp: user.timestamp
            )
        }

        let signingSecret = try signingKey.withUnsafeBytes { bytes in
            try SecretPayload(
                secretType: .userSigningKey,
                objectId: nil,
                encrypting: bytes,
                usingRecoveryKey: recoveryKey,
                timestamp: user.timestamp
            )
        }

        let payload = RegisterNewPayload(
            user: user,
            userKey: try UserKeyPayload(userKey: localUserKey),
            recoverySecret: recoverySecret,
            signingSecret: signingSecret
        )

        _ = try await APIRequest(
            path: "register/\(token.urlSafeBase64EncodedString)/new",
            method: .post,
            session: nil,
            payload: payload
        )
        .send { event in
            if event.eventType == .userKeyRecord {
                let decoded = try event.decode(as: UserKeyPayload.self)

                guard decoded.userId == localUserKey.id,
                    decoded.signingKey == localUserKey.signing
                else {
                    throw error("User key provided by server does not match.")
                }

                localUserKey.timestamp = decoded.timestamp
                let finalUserKey = localUserKey

                try KeychainStorage.shared.save(
                    signingKey,
                    to: .userSigningKey(finalUserKey.id)
                )

                try await dataStore.write { db in
                    try finalUserKey.insert(db)
                }

                return true
            } else {
                // Default handling for this event.
                return false
            }
        }
    }
}

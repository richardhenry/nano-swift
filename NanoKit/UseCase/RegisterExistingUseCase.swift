//
//  RegisterExistingUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/25/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public struct RegisterExistingUseCase: UseCase {
    public class RecoveryKeyRequiredError: AnyError {}

    public var token: CheckByteToken
    public var challenge: RegisterValidatePayload.Challenge
    public var ephemeralRecoveryKey: SymmetricKey?
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        token: CheckByteToken,
        challenge: RegisterValidatePayload.Challenge,
        ephemeralRecoveryKey: SymmetricKey?,
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.token = token
        self.challenge = challenge
        self.ephemeralRecoveryKey = ephemeralRecoveryKey
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        if let ephemeralRecoveryKey {
            try keychainStorage.save(
                ephemeralRecoveryKey,
                to: .ephemeralRecoveryKey(challenge.userId)
            )
        } else if try !keychainStorage.exists(.ephemeralRecoveryKey(challenge.userId)) {
            throw error("Recovery key is required.", as: RecoveryKeyRequiredError.self)
        }

        try await SecretSaveUseCase(
            userId: challenge.userId,
            secret: challenge.recoverySecret,
            dataStore: dataStore,
            keychainStorage: keychainStorage
        )
        .run()
        try await SecretSaveUseCase(
            userId: challenge.userId,
            secret: challenge.signingSecret,
            dataStore: dataStore,
            keychainStorage: keychainStorage
        )
        .run()

        let signingKey: Curve25519.Signing.PrivateKey = try keychainStorage.get(
            .userSigningKey(challenge.userId)
        )

        let payload = RegisterExistingPayload(
            signature: try signingKey.signature(
                for: token.combinedValue.withUseCaseByte(.registerSignature)
            )
        )

        _ = try await APIRequest(
            path: "register/\(token.urlSafeBase64EncodedString)/existing",
            method: .post,
            session: nil,
            payload: payload
        )
        .send()
    }
}

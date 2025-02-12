//
//  SecretSaveUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/24/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

struct SecretSaveUseCase: UseCase {
    var userId: UserID
    var secret: SecretPayload
    var dataStore: DataStore = .shared
    var keychainStorage: KeychainStorage = .shared

    func run() async throws {
        let recoveryKey: SymmetricKey = try keychainStorage.get(
            secret.secretType == .recoveryKey ? .ephemeralRecoveryKey(userId) : .recoveryKey(userId)
        )

        let decryptedValue = try secret.decryptSecret(recoveryKey: recoveryKey)

        switch secret.secretType {
        case .recoveryKey:
            let key = SymmetricKey(data: decryptedValue)
            try keychainStorage.save(key, to: .recoveryKey(userId))

        case .userSigningKey:
            let key = try Curve25519.Signing.PrivateKey(rawRepresentation: decryptedValue)
            try keychainStorage.save(key, to: .userSigningKey(userId))

        case .memberKey:
            let pack = try SecureBytePack(
                from: decryptedValue,
                layout: [
                    .item(Curve25519.KeyAgreement.PrivateKey.self),
                    .item(Kyber1024.PrivateKey.self),
                    .item(Curve25519.KeyAgreement.PrivateKey.self),
                ]
            )

            guard let groupId: GroupID = secret.objectId?.asType() else {
                throw error("Member key secret does not specify a group ID.")
            }

            let storeKey: Curve25519.KeyAgreement.PrivateKey = try pack.item(at: 0)
            try keychainStorage.save(storeKey, to: .memberStoreKey(userId, groupId))

            let storeKeyKyber: Kyber1024.PrivateKey = try pack.item(at: 1)
            try keychainStorage.save(
                storeKeyKyber,
                to: .memberStoreKeyKyber(userId, groupId)
            )

            let authKey: Curve25519.KeyAgreement.PrivateKey = try pack.item(at: 2)
            try keychainStorage.save(authKey, to: .memberAuthKey(userId, groupId))

        case .inviteSecretKey:
            guard let virtualId: VirtualMemberID = secret.objectId?.asType() else {
                throw error("Invite secret key does not specify a virtual ID.")
            }

            let key = SymmetricKey(data: decryptedValue)
            try keychainStorage.save(key, to: .inviteSecretKey(virtualId))
        }
    }

    static func memberKeyBundle(
        storeKey: Curve25519.KeyAgreement.PrivateKey,
        storeKeyKyber: Kyber1024.PrivateKey,
        authKey: Curve25519.KeyAgreement.PrivateKey
    ) throws -> Data {
        try SecureBytePack([
            storeKey,
            storeKeyKyber,
            authKey,
        ])
        .pack()
    }
}

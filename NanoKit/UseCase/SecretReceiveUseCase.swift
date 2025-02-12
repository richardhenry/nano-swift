//
//  SecretUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/24/24.
//

import CryptoKit
import Foundation
import NanoCrypto

enum SecretReceiveUseCaseError: Error {
    case missingTargetId
}

struct SecretUseCase: UseCase {
    var secret: SecretPayload
    var dataStore: DataStore = .shared
    var keychainStorage: KeychainStorage = .shared

    func run() async throws {
        let session = try await dataStore.read { db in
            try SessionModel.fetchExpect(db)
        }

        let recoveryKey: SymmetricKey = try keychainStorage.get(
            .recoveryKey(session.userId)
        )

        let data = try secret.decryptSecret(recoveryKey: recoveryKey)

        switch secret.secretType {
        case .recoverySecret:
            let key = SymmetricKey(data: data)
            try keychainStorage.save(key, to: .recoveryKey(session.userId))

        case .userSigningKey:
            let key = try Curve25519.Signing.PrivateKey(rawRepresentation: data)
            try keychainStorage.save(key, to: .userSigningKey(session.userId))

        case .memberKeyBundle:
            let pack = try SecureBytePack(
                from: data,
                layout: [
                    .item(Curve25519.KeyAgreement.PrivateKey.self),
                    .item(Kyber1024.PrivateKey.self),
                    .item(Curve25519.KeyAgreement.PrivateKey.self),
                ]
            )

            guard let groupId: GroupID = secret.objectId?.into() else {
                throw SecretReceiveUseCaseError.missingTargetId
            }

            let storeKey: Curve25519.KeyAgreement.PrivateKey = try pack.item(at: 0)
            try keychainStorage.save(storeKey, to: .memberStoreKey(session.userId, groupId))

            let storeKeyKyber: Kyber1024.PrivateKey = try pack.item(at: 1)
            try keychainStorage.save(
                storeKeyKyber,
                to: .memberStoreKeyKyber(session.userId, groupId)
            )

            let authKey: Curve25519.KeyAgreement.PrivateKey = try pack.item(at: 2)
            try keychainStorage.save(authKey, to: .memberAuthKey(session.userId, groupId))

        case .inviteSecretKey:
            guard let virtualId: VirtualMemberID = secret.objectId?.into() else {
                throw SecretReceiveUseCaseError.missingTargetId
            }

            let key = SymmetricKey(data: data)
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

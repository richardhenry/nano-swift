//
//  EpochDeriveUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 3/28/24.
//

import CryptoKit
import Foundation
import NanoCrypto

public struct EpochDeriveUseCase {
    static func deriveChainingKeys(
        previousRootKey rootKey: SymmetricKey,
        nextEpochId epochId: EpochID
    ) -> (chainingKey: SymmetricKey, preSharedKey: SymmetricKey) {
        HKDF<SHA256>
            .deriveKey(
                inputKeyMaterial: rootKey,
                info: Data("epoch_chaining_keys_\(epochId.base64EncodedString)".utf8),
                outputByteCount: 64
            )
            .withUnsafeBytes { bytes in
                (SymmetricKey(data: bytes.prefix(32)), SymmetricKey(data: bytes.suffix(32)))
            }
    }

    static func deriveNextRootKey(
        newEntropy entropy: SymmetricKey,
        chainingKey: SymmetricKey
    ) -> SymmetricKey {
        chainingKey.withUnsafeBytes { bytes in
            HKDF<SHA256>
                .deriveKey(
                    inputKeyMaterial: entropy,
                    salt: bytes,
                    info: Data("epoch_root_key".utf8),
                    outputByteCount: 32
                )
        }
    }

    static func deriveMacKey(
        epochId: EpochID,
        rootKey: SymmetricKey
    ) -> SymmetricKey {
        rootKey.withUnsafeBytes { bytes in
            HKDF<SHA256>
                .deriveKey(
                    inputKeyMaterial: rootKey,
                    info: Data("epoch_auth_mac_key_\(epochId.base64EncodedString)".utf8),
                    outputByteCount: 32
                )
        }
    }

    static func generateMac(
        macKey: SymmetricKey,
        publicSigningKey: Curve25519.Signing.PublicKey
    ) -> Data {
        macKey.withUnsafeBytes { bytes in
            return HMAC<SHA256>
                .authenticationCode(
                    for: bytes,
                    using: SymmetricKey(data: publicSigningKey.rawRepresentation)
                )
        }
        .withUnsafeBytes { Data($0) }
    }
}

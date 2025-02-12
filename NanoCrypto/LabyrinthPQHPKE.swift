//
//  LabyrinthPQHPKE.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/21/24.
//

import CryptoKit
import Foundation
import NanoCore

public enum LabyrinthPQHPKE {
    public static func seal<Plaintext: DataProtocol, AuthenticatedData: DataProtocol>(
        recipientKey: Curve25519.KeyAgreement.PublicKey,
        recipientKeyKyber: Kyber1024.PublicKey,
        senderKey: Curve25519.KeyAgreement.PrivateKey,
        preSharedKey: SymmetricKey,
        message: Plaintext,
        authenticating authenticatedData: AuthenticatedData
    ) throws -> SealedBox {
        guard preSharedKey.bitCount == 256 else {
            throw error("PSK size is incorrect.")
        }

        let ephemeralKey = Curve25519.KeyAgreement.PrivateKey()

        let (kyberSharedSecret, kyberCiphertext) = try recipientKeyKyber.encrypt()

        let ikm = try initialKeyingMaterial(
            senderSharedSecret: try senderKey.sharedSecretFromKeyAgreement(with: recipientKey),
            ephemeralSharedSecret: try ephemeralKey.sharedSecretFromKeyAgreement(
                with: recipientKey
            ),
            kyberSharedSecret: kyberSharedSecret
        )

        let keyAuthenticatedData =
            Data("labyrinth_pqhpke".utf8) + senderKey.publicKey.rawRepresentation
            + recipientKey.rawRepresentation + ephemeralKey.publicKey.rawRepresentation
            + Data(authenticatedData)

        let key = try deriveKey(
            initialKeyingMaterial: ikm,
            preSharedKey: preSharedKey,
            authenticatedData: keyAuthenticatedData
        )

        let nonce = try ChaChaPolyIETF.Nonce(
            data: Data(repeating: 0, count: ChaChaPolyIETF.nonceBytes)
        )
        let sealedBox = try ChaChaPolyIETF.seal(
            message,
            using: key,
            nonce: nonce,
            authenticating: authenticatedData
        )

        let combined =
            Data([SealedBox.headerByte]) + ephemeralKey.publicKey.rawRepresentation
            + sealedBox.combined
            + kyberCiphertext.rawRepresentation

        return try SealedBox(combined: combined)
    }

    public static func open<AuthenticatedData: DataProtocol>(
        _ sealedBox: SealedBox,
        recipientKey: Curve25519.KeyAgreement.PrivateKey,
        recipientKeyKyber: Kyber1024.PrivateKey,
        senderKey: Curve25519.KeyAgreement.PublicKey,
        preSharedKey: SymmetricKey,
        authenticating authenticatedData: AuthenticatedData,
        intoSecureMemory: Bool = true
    ) throws -> Data {
        let ephemeralKey = try sealedBox.ephemeralKey
        let kyberCiphertext = try sealedBox.kyberCiphertext
        let innerBox = try sealedBox.innerBox

        let kyberSharedSecret = try recipientKeyKyber.decrypt(ciphertext: kyberCiphertext)

        let ikm = try initialKeyingMaterial(
            senderSharedSecret: try recipientKey.sharedSecretFromKeyAgreement(with: senderKey),
            ephemeralSharedSecret: try recipientKey.sharedSecretFromKeyAgreement(
                with: ephemeralKey
            ),
            kyberSharedSecret: kyberSharedSecret
        )

        let keyAuthenticatedData =
            Data("labyrinth_pqhpke".utf8) + senderKey.rawRepresentation
            + recipientKey.publicKey.rawRepresentation + ephemeralKey.rawRepresentation
            + Data(authenticatedData)

        let key = try deriveKey(
            initialKeyingMaterial: ikm,
            preSharedKey: preSharedKey,
            authenticatedData: keyAuthenticatedData
        )

        return try ChaChaPolyIETF.open(
            innerBox,
            using: key,
            authenticating: authenticatedData,
            intoSecureMemory: intoSecureMemory
        )
    }
}

// MARK: Sealed
extension LabyrinthPQHPKE {
    public struct SealedBox {
        static let headerByte: UInt8 = 76  // "L"

        /// The combined data. The layout is: ephemeral key, ChaCha20-Poly1305 sealed box, kyber ciphertext.
        public let combined: Data

        /// Returns the inner sealed box.
        public var innerBox: ChaChaPolyIETF.SealedBox {
            get throws {
                try ChaChaPolyIETF.SealedBox(
                    combined: combined.dropFirst(33).dropLast(Kyber1024.Ciphertext.sizeBytes)
                )
            }
        }

        /// Returns the public ephemeral Curve25519 key.
        public var ephemeralKey: Curve25519.KeyAgreement.PublicKey {
            get throws {
                try Curve25519.KeyAgreement.PublicKey(
                    rawRepresentation: combined.dropFirst().prefix(32)
                )
            }
        }

        /// Returns the Kyber1024 ciphertext.
        public var kyberCiphertext: Kyber1024.Ciphertext {
            get throws {
                try Kyber1024.Ciphertext(
                    rawRepresentation: combined.suffix(Kyber1024.Ciphertext.sizeBytes)
                )
            }
        }

        /// Creates a new sealed box from combined data or throws if the size is incorrect.
        public init<D: DataProtocol>(combined: D) throws {
            guard combined.first == Self.headerByte else {
                throw error("Header byte is missing or corrupted.")
            }
            guard
                combined.count >= 1 + 32 + Kyber1024.Ciphertext.sizeBytes
                    + ChaChaPolyIETF.nonceBytes
                    + ChaChaPolyIETF.tagBytes
            else {
                throw error("Sealed box size is insufficient.")
            }
            self.combined = Data(combined)
        }
    }
}

// MARK: IKM
extension LabyrinthPQHPKE {
    static func initialKeyingMaterial(
        senderSharedSecret: SharedSecret,
        ephemeralSharedSecret: SharedSecret,
        kyberSharedSecret: Kyber1024.SharedSecret
    ) throws -> SecureBytes {
        assert(senderSharedSecret.withUnsafeBytes { $0.count } == 32)
        assert(ephemeralSharedSecret.withUnsafeBytes { $0.count } == 32)

        return try SecureBytes(unsafeUninitializedCapacity: initialKeyingMaterialBytes) {
            ikmPointer,
            outBytes in
            senderSharedSecret.withUnsafeBytes { bytes in
                ikmPointer.baseAddress!
                    .copyMemory(
                        from: bytes.baseAddress!,
                        byteCount: bytes.count
                    )
                outBytes += bytes.count
            }

            ephemeralSharedSecret.withUnsafeBytes { bytes in
                ikmPointer.baseAddress!.advanced(by: outBytes)
                    .copyMemory(
                        from: bytes.baseAddress!,
                        byteCount: bytes.count
                    )
                outBytes += bytes.count
            }

            kyberSharedSecret.withUnsafeBytes { bytes in
                ikmPointer.baseAddress!.advanced(by: outBytes)
                    .copyMemory(
                        from: bytes.baseAddress!,
                        byteCount: bytes.count
                    )
                outBytes += bytes.count
            }

            guard outBytes == initialKeyingMaterialBytes else {
                throw error("IKM size is incorrect.")
            }
        }
    }

    static let initialKeyingMaterialBytes = 32 + 32 + Kyber1024.SharedSecret.sizeBytes
}

// MARK: HKDF
extension LabyrinthPQHPKE {
    static func deriveKey(
        initialKeyingMaterial: SecureBytes,
        preSharedKey: SymmetricKey,
        authenticatedData: Data
    ) throws -> SymmetricKey {
        let ikm = initialKeyingMaterial.withUnsafeBytes { SymmetricKey(data: $0) }
        assert(ikm.bitCount == initialKeyingMaterialBytes * 8)

        return preSharedKey.withUnsafeBytes { pskBytes in
            HKDF<SHA256>
                .deriveKey(
                    inputKeyMaterial: ikm,
                    salt: pskBytes,
                    info: authenticatedData,
                    outputByteCount: 32
                )
        }
    }
}

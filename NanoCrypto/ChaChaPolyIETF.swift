//
//  ChaChaPolyIETF.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/21/24.
//

import Clibsodium
import CryptoKit
import Foundation
import NanoCore

/// An implementation of the IETF variant of the ChaCha20-Poly1305 cipher.
public enum ChaChaPolyIETF {
    /// Encrypts the provided plaintext with an authentication tag and additional data.
    ///
    /// - Parameters:
    ///   - message: The plaintext data to seal.
    ///   - key: The symmetric key used to seal the message.
    ///   - nonce: The nonce the encryption process requires. If you don't provide a nonce, a random one will be generated for you.
    ///   - authenticatedData: Additional data to be authenticated.
    /// - Returns: A sealed box.
    public static func seal<Plaintext: DataProtocol, AuthenticatedData: DataProtocol>(
        _ message: Plaintext,
        using key: SymmetricKey,
        nonce: Nonce? = nil,
        authenticating authenticatedData: AuthenticatedData
    ) throws -> SealedBox {
        guard key.bitCount == ChaChaPolyIETF.keyBytes * 8 else {
            throw error("Key size is incorrect.")
        }

        let nonce = nonce ?? Nonce()
        let ciphertext: Data
        let tag: Data

        switch (message.regions.count, authenticatedData.regions.count) {
        case (1, 1):
            (ciphertext, tag) = try self.sealContiguous(
                message: message.regions.first!,
                key: key,
                nonce: nonce,
                authenticatedData: authenticatedData.regions.first!
            )
        case (1, _):
            let contiguousAD = Array(authenticatedData)
            (ciphertext, tag) = try self.sealContiguous(
                message: message.regions.first!,
                key: key,
                nonce: nonce,
                authenticatedData: contiguousAD
            )
        case (_, 1):
            let contiguousMessage = Array(message)
            (ciphertext, tag) = try self.sealContiguous(
                message: contiguousMessage,
                key: key,
                nonce: nonce,
                authenticatedData: authenticatedData.regions.first!
            )
        case (_, _):
            let contiguousMessage = Array(message)
            let contiguousAD = Array(authenticatedData)
            (ciphertext, tag) = try self.sealContiguous(
                message: contiguousMessage,
                key: key,
                nonce: nonce,
                authenticatedData: contiguousAD
            )
        }

        return try SealedBox(combined: nonce.data + ciphertext + tag)
    }

    /// Encrypts the provided plaintext with an authentication tag.
    ///
    /// - Parameters:
    ///   - message: The plaintext data to seal.
    ///   - key: The symmetric key used to seal the message.
    ///   - nonce: The nonce the encryption process requires. If you don't provide a nonce, a random one will be generated for you.
    /// - Returns: A sealed box.
    public static func seal<Plaintext: DataProtocol>(
        _ message: Plaintext,
        using key: SymmetricKey,
        nonce: Nonce? = nil
    ) throws -> SealedBox {
        try seal(message, using: key, nonce: nonce, authenticating: [])
    }

    /// Decrypts a sealed box validating the authenticity of the message and the additional authenticated data.
    ///
    /// - Parameters:
    ///   - sealedBox: The sealed box to open.
    ///   - key: The cryptographic key that was used to seal the box.
    ///   - authenticatedData: Additional data to be verified.
    ///   - intoSecureMemory: If true, secure memory will be used for the plaintext allocation. This should be used if the plaintext contains secret key material.
    /// - Returns: The decrypted plaintext, as long as the correct key was used and the authentication succeeds.
    public static func open<AuthenticatedData: DataProtocol>(
        _ sealedBox: SealedBox,
        using key: SymmetricKey,
        authenticating authenticatedData: AuthenticatedData,
        intoSecureMemory: Bool = false
    ) throws -> Data {
        if authenticatedData.regions.count == 1 {
            return try self.openContiguous(
                ciphertext: sealedBox.ciphertext,
                nonce: sealedBox.nonce.data,
                tag: sealedBox.tag,
                key: key,
                authenticatedData: authenticatedData.regions.first!,
                intoSecureMemory: intoSecureMemory
            )
        } else {
            let contiguousAD = Array(authenticatedData)
            return try self.openContiguous(
                ciphertext: sealedBox.ciphertext,
                nonce: sealedBox.nonce.data,
                tag: sealedBox.tag,
                key: key,
                authenticatedData: contiguousAD,
                intoSecureMemory: intoSecureMemory
            )
        }
    }

    /// Decrypts a sealed box validating the authenticity of the message.
    ///
    /// - Parameters:
    ///   - sealedBox: The sealed box to open.
    ///   - key: The cryptographic key that was used to seal the box.
    ///   - intoSecureMemory: If true, secure memory will be used for the plaintext allocation. This should be used if the plaintext contains secret key material.
    /// - Returns: The decrypted plaintext, as long as the correct key was used and the authentication succeeds.
    public static func open(
        _ sealedBox: SealedBox,
        using key: SymmetricKey,
        intoSecureMemory: Bool = false
    ) throws -> Data {
        try open(sealedBox, using: key, authenticating: [], intoSecureMemory: intoSecureMemory)
    }

    public static let keyBytes = Int(crypto_aead_chacha20poly1305_ietf_KEYBYTES)
    public static let tagBytes = Int(crypto_aead_chacha20poly1305_IETF_ABYTES)
    public static let nonceBytes = Int(crypto_aead_chacha20poly1305_IETF_NPUBBYTES)
}

extension ChaChaPolyIETF {
    /// A secure container holding the authentication tag, ciphertext, and nonce.
    public struct SealedBox {
        /// The combined data. The layout is: nonce, ciphertext, tag.
        public let combined: Data

        /// An 16 byte authentication tag.
        public var tag: Data {
            combined.suffix(ChaChaPolyIETF.tagBytes)
        }

        /// The ciphertext.
        public var ciphertext: Data {
            combined.dropFirst(ChaChaPolyIETF.nonceBytes).dropLast(ChaChaPolyIETF.tagBytes)
        }

        /// The nonce used to encrypt the data.
        public var nonce: Nonce {
            try! Nonce(data: combined.prefix(ChaChaPolyIETF.nonceBytes))
        }

        /// Creates a new sealed box from combined data or throws if the size is incorrect.
        public init<D: DataProtocol>(combined: D) throws {
            guard combined.count >= ChaChaPolyIETF.nonceBytes + ChaChaPolyIETF.tagBytes else {
                throw error("Sealed box size is insufficient.")
            }
            self.combined = Data(combined)
        }
    }
}

extension ChaChaPolyIETF {
    /// A "number once" used during encryption. Never reuse the same nonce for subsequent encryption calls.
    public struct Nonce {
        public var data: Data

        /// Creates a new random 12 byte nonce.
        public init() {
            data = Data(randomBytes: ChaChaPolyIETF.nonceBytes)
        }

        /// Creates a nonce from the given data or throws if the size is incorrect.
        public init<D: DataProtocol>(data: D) throws {
            guard data.count == ChaChaPolyIETF.nonceBytes else {
                throw error("Nonce size is incorrect.")
            }
            self.data = Data(data)
        }
    }
}

// MARK: - Sealing

extension ChaChaPolyIETF {
    @inlinable
    static func sealContiguous<Plaintext: ContiguousBytes, AuthenticatedData: ContiguousBytes>(
        message: Plaintext,
        key: SymmetricKey,
        nonce: Nonce,
        authenticatedData: AuthenticatedData
    ) throws -> (ciphertext: Data, tag: Data) {
        try message.withUnsafeBytes { messagePointer in
            try key.withUnsafeBytes { keyPointer in
                try nonce.data.withUnsafeBytes { noncePointer in
                    try authenticatedData.withUnsafeBytes { authenticatedDataPointer in
                        try self.sealContiguous(
                            plaintext: messagePointer,
                            key: keyPointer,
                            nonce: noncePointer,
                            authenticatedData: authenticatedDataPointer
                        )
                    }
                }
            }
        }
    }

    @usableFromInline
    static func sealContiguous(
        plaintext: UnsafeRawBufferPointer,
        key: UnsafeRawBufferPointer,
        nonce: UnsafeRawBufferPointer,
        authenticatedData: UnsafeRawBufferPointer
    ) throws -> (ciphertext: Data, tag: Data) {
        let ciphertextBuffer = UnsafeMutableRawBufferPointer(
            start: malloc(plaintext.count)!,
            count: plaintext.count
        )
        let tagBuffer = UnsafeMutableRawBufferPointer(
            start: malloc(Self.tagBytes)!,
            count: Self.tagBytes
        )
        var tagSize = UInt64(tagBuffer.count)

        let result = crypto_aead_chacha20poly1305_ietf_encrypt_detached(
            ciphertextBuffer.baseAddress!,
            tagBuffer.baseAddress!,
            &tagSize,
            plaintext.baseAddress!,
            UInt64(plaintext.count),
            authenticatedData.baseAddress,
            UInt64(authenticatedData.count),
            nil,
            nonce.baseAddress!,
            key.baseAddress!
        )

        guard result == 0 else {
            free(ciphertextBuffer.baseAddress)
            free(tagBuffer.baseAddress)
            throw error("Encryption failed with error: \(result)")
        }

        let ciphertext = Data(
            bytesNoCopy: ciphertextBuffer.baseAddress!,
            count: ciphertextBuffer.count,
            deallocator: .free
        )
        let tag = Data(bytesNoCopy: tagBuffer.baseAddress!, count: Int(tagSize), deallocator: .free)

        return (ciphertext, tag)
    }
}

// MARK: - Opening

extension ChaChaPolyIETF {
    @inlinable
    static func openContiguous<AuthenticatedData: ContiguousBytes>(
        ciphertext: Data,
        nonce: Data,
        tag: Data,
        key: SymmetricKey,
        authenticatedData: AuthenticatedData,
        intoSecureMemory: Bool
    ) throws -> Data {
        try ciphertext.withUnsafeBytes { ciphertextPointer in
            try nonce.withUnsafeBytes { noncePointer in
                try tag.withUnsafeBytes { tagPointer in
                    try key.withUnsafeBytes { keyPointer in
                        try authenticatedData.withUnsafeBytes { authenticatedDataPointer in
                            if intoSecureMemory {
                                try self.openContiguousSecure(
                                    ciphertext: ciphertextPointer,
                                    nonce: noncePointer,
                                    tag: tagPointer,
                                    key: keyPointer,
                                    authenticatedData: authenticatedDataPointer
                                )
                            } else {
                                try self.openContiguous(
                                    ciphertext: ciphertextPointer,
                                    nonce: noncePointer,
                                    tag: tagPointer,
                                    key: keyPointer,
                                    authenticatedData: authenticatedDataPointer
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    @usableFromInline
    static func openContiguous(
        ciphertext: UnsafeRawBufferPointer,
        nonce: UnsafeRawBufferPointer,
        tag: UnsafeRawBufferPointer,
        key: UnsafeRawBufferPointer,
        authenticatedData: UnsafeRawBufferPointer
    ) throws -> Data {
        let plaintextBuffer = UnsafeMutableRawBufferPointer(
            start: malloc(ciphertext.count)!,
            count: ciphertext.count
        )

        let result = crypto_aead_chacha20poly1305_ietf_decrypt_detached(
            plaintextBuffer.baseAddress!,
            nil,
            ciphertext.baseAddress!,
            UInt64(ciphertext.count),
            tag.baseAddress!,
            authenticatedData.baseAddress!,
            UInt64(authenticatedData.count),
            nonce.baseAddress!,
            key.baseAddress!
        )

        guard result == 0 else {
            free(plaintextBuffer.baseAddress)
            throw error("Decryption failed with error: \(result)")
        }

        return Data(
            bytesNoCopy: plaintextBuffer.baseAddress!,
            count: plaintextBuffer.count,
            deallocator: .free
        )
    }

    @usableFromInline
    static func openContiguousSecure(
        ciphertext: UnsafeRawBufferPointer,
        nonce: UnsafeRawBufferPointer,
        tag: UnsafeRawBufferPointer,
        key: UnsafeRawBufferPointer,
        authenticatedData: UnsafeRawBufferPointer
    ) throws -> Data {
        let secureBytes = try SecureBytes(unsafeUninitializedCapacity: ciphertext.count) {
            plaintextBuffer,
            outBytes in
            let result = crypto_aead_chacha20poly1305_ietf_decrypt_detached(
                plaintextBuffer.baseAddress!,
                nil,
                ciphertext.baseAddress!,
                UInt64(ciphertext.count),
                tag.baseAddress!,
                authenticatedData.baseAddress!,
                UInt64(authenticatedData.count),
                nonce.baseAddress!,
                key.baseAddress!
            )

            guard result == 0 else {
                throw error("Decryption failed with error: \(result)")
            }

            outBytes = plaintextBuffer.count
        }

        return Data(secureBytes)  // Does not copy.
    }
}

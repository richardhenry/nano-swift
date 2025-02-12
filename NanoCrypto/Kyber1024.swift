//
//  Kyber1024.swift
//  NanoCrypto
//
//  Created by Richard Henry on 1/8/24.
//

import Ckyber1024
import Foundation
import NanoCore

public enum Kyber1024 {
    public static func pair() throws -> Pair {
        var privateKey = PrivateKey()
        var publicKey = PublicKey()

        let result = publicKey.bytes.withUnsafeMutableBytes { pkPtr in
            privateKey.bytes.withUnsafeMutableBytes { skPtr in
                PQCLEAN_KYBER1024_CLEAN_crypto_kem_keypair(
                    pkPtr.bindMemory(to: UInt8.self).baseAddress,
                    skPtr.bindMemory(to: UInt8.self).baseAddress
                )
            }
        }

        guard result == 0 else {
            throw error("Key pair generation failed with error: \(result)")
        }

        return Pair(privateKey: privateKey, publicKey: publicKey)
    }

    public struct Pair {
        public var privateKey: PrivateKey
        public var publicKey: PublicKey

        public init(privateKey: PrivateKey, publicKey: PublicKey) {
            self.privateKey = privateKey
            self.publicKey = publicKey
        }
    }

    public struct SharedSecret: SizeBytes {
        public static let sizeBytes = Int(PQCLEAN_KYBER1024_CLEAN_CRYPTO_BYTES)

        var bytes: SecureBytes

        public var rawRepresentation: Data {
            Data(bytes)
        }

        public init<D>(rawRepresentation: D) throws where D: ContiguousBytes {
            bytes = SecureBytes(bytes: rawRepresentation)
        }

        init() {
            self.bytes = SecureBytes(zeroBytes: Self.sizeBytes)
        }
    }

    public struct Ciphertext: SizeBytes {
        public static let sizeBytes = Int(PQCLEAN_KYBER1024_CLEAN_CRYPTO_CIPHERTEXTBYTES)

        var bytes: [UInt8]

        public var rawRepresentation: Data {
            Data(bytes)
        }

        public init<D>(rawRepresentation: D) throws where D: ContiguousBytes {
            bytes = try rawRepresentation.withUnsafeBytes { dataPtr in
                guard dataPtr.count == Self.sizeBytes else {
                    throw error("Wrong number of bytes.")
                }
                return Array(dataPtr)
            }
        }

        init() {
            self.bytes = Array(repeating: 0, count: Self.sizeBytes)
        }
    }

    public struct PublicKey: SizeBytes {
        public static let sizeBytes = Int(PQCLEAN_KYBER1024_CLEAN_CRYPTO_PUBLICKEYBYTES)

        var bytes: [UInt8]

        public var rawRepresentation: Data {
            Data(bytes)
        }

        public init<D>(rawRepresentation: D) throws where D: ContiguousBytes {
            bytes = try rawRepresentation.withUnsafeBytes { dataPtr in
                guard dataPtr.count == Self.sizeBytes else {
                    throw error("Wrong number of bytes.")
                }
                return Array(dataPtr)
            }
        }

        init() {
            self.bytes = Array(repeating: 0, count: Self.sizeBytes)
        }

        public func encrypt() throws -> (SharedSecret, Ciphertext) {
            var ciphertext = Ciphertext()
            var sharedSecret = SharedSecret()

            let result = bytes.withUnsafeBytes { pkPtr in
                ciphertext.bytes.withUnsafeMutableBytes { ctPtr in
                    sharedSecret.bytes.withUnsafeMutableBytes { ssPtr in
                        PQCLEAN_KYBER1024_CLEAN_crypto_kem_enc(
                            ctPtr.bindMemory(to: UInt8.self).baseAddress,
                            ssPtr.bindMemory(to: UInt8.self).baseAddress,
                            pkPtr.bindMemory(to: UInt8.self).baseAddress
                        )
                    }
                }
            }

            guard result == 0 else {
                throw error("Encryption failed with error: \(result)")
            }

            return (sharedSecret, ciphertext)
        }
    }

    public struct PrivateKey: SizeBytes {
        public static let sizeBytes = Int(PQCLEAN_KYBER1024_CLEAN_CRYPTO_SECRETKEYBYTES)

        var bytes: SecureBytes

        public private(set) var publicKey: PublicKey?

        public var rawRepresentation: Data {
            Data(bytes)
        }

        public init<D>(rawRepresentation: D) throws where D: ContiguousBytes {
            bytes = SecureBytes(bytes: rawRepresentation)
        }

        init() {
            self.bytes = SecureBytes(zeroBytes: Self.sizeBytes)
        }

        public func decrypt(ciphertext: Ciphertext) throws -> SharedSecret {
            var sharedSecret = SharedSecret()

            let result = sharedSecret.bytes.withUnsafeMutableBytes { ssPtr in
                bytes.withUnsafeBytes { skPtr in
                    ciphertext.bytes.withUnsafeBytes { ctPtr in
                        PQCLEAN_KYBER1024_CLEAN_crypto_kem_dec(
                            ssPtr.bindMemory(to: UInt8.self).baseAddress,
                            ctPtr.bindMemory(to: UInt8.self).baseAddress,
                            skPtr.bindMemory(to: UInt8.self).baseAddress
                        )
                    }
                }
            }

            guard result == 0 else {
                throw error("Decryption failed with error: \(result)")
            }

            return sharedSecret
        }
    }
}

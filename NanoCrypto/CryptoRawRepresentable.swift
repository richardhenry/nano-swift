//
//  CryptoRawRepresentable.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/19/24.
//

import CryptoKit
import Foundation

public protocol CryptoRawRepresentable {
    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes
    var rawRepresentation: Data { get }
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
}

extension SymmetricKey: CryptoRawRepresentable {
    public var rawRepresentation: Data {
        withUnsafeBytes { bytes in
            // Don't copy the key data out of secure memory.
            CFDataCreateWithBytesNoCopy(
                nil,
                bytes.baseAddress!.assumingMemoryBound(to: UInt8.self),
                bytes.count,
                kCFAllocatorNull
            )
                as Data
        }
    }

    public init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        self.init(data: data)
    }
}

extension InsecureCodableSymmetricKey: CryptoRawRepresentable {
    public var rawRepresentation: Data {
        rawValue.rawRepresentation
    }

    public init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        self = .init(rawValue: try SymmetricKey(rawRepresentation: data))
    }

    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try rawValue.withUnsafeBytes(body)
    }
}

extension Curve25519.Signing.PrivateKey: CryptoRawRepresentable {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try rawRepresentation.withUnsafeBytes(body)
    }
}

extension Curve25519.Signing.PublicKey: CryptoRawRepresentable {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try rawRepresentation.withUnsafeBytes(body)
    }
}

extension Curve25519.KeyAgreement.PrivateKey: CryptoRawRepresentable {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try rawRepresentation.withUnsafeBytes(body)
    }
}

extension Curve25519.KeyAgreement.PublicKey: CryptoRawRepresentable {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try rawRepresentation.withUnsafeBytes(body)
    }
}

extension Kyber1024.PrivateKey: CryptoRawRepresentable {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try rawRepresentation.withUnsafeBytes(body)
    }
}

extension Kyber1024.PublicKey: CryptoRawRepresentable {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try rawRepresentation.withUnsafeBytes(body)
    }
}

extension Kyber1024.SharedSecret: CryptoRawRepresentable {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try rawRepresentation.withUnsafeBytes(body)
    }
}

extension Kyber1024.Ciphertext: CryptoRawRepresentable {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try rawRepresentation.withUnsafeBytes(body)
    }
}

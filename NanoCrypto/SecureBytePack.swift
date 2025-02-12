//
//  SecureBytePack.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/19/24.
//

import CryptoKit
import Foundation
import NanoCore

public struct SecureBytePack {
    public struct Item {
        public var type: SecureBytePackable.Type
        public var sizeBytes: Int

        public static func item(_ type: (SecureBytePackable & SizeBytes).Type) -> Self {
            self.init(type: type, sizeBytes: type.sizeBytes)
        }

        public static func item(_ type: SecureBytePackable.Type, sizeBytes: Int) -> Self {
            self.init(type: type, sizeBytes: sizeBytes)
        }
    }

    let items: [SecureBytePackable]

    public init(_ items: [SecureBytePackable]) {
        self.items = items
    }

    public init(from data: Data, layout: [Item]) throws {
        let expectedSize = layout.map({ $0.sizeBytes }).reduce(0, +)
        guard expectedSize == data.count else {
            throw error("Byte pack is the wrong size. Expected: \(expectedSize) Got: \(data.count)")
        }

        var unpacked = [SecureBytePackable]()

        try data.withUnsafeBytes { bytes in
            var offset = 0
            for item in layout {
                let slice = bytes[offset..<offset + item.sizeBytes]
                unpacked.append(try item.type.init(rawRepresentation: slice))
                offset += item.sizeBytes
            }
        }

        self.items = unpacked
    }

    public func pack() throws -> Data {
        let size = items.map { $0.withUnsafeBytes { $0.count } }.reduce(0, +)

        let secureBytes = SecureBytes(unsafeUninitializedCapacity: size) { outPtr, outBytes in
            var offset = 0
            for item in items {
                item.withUnsafeBytes { keyPtr in
                    outPtr.baseAddress!.advanced(by: offset)
                        .copyMemory(from: keyPtr.baseAddress!, byteCount: keyPtr.count)
                    offset += keyPtr.count
                }
            }
            outBytes = offset
        }

        return Data(secureBytes)
    }

    public func item<T: SecureBytePackable>(at index: Int) throws -> T {
        guard items.count > index else {
            throw error("Item at index \(index) does not exist.")
        }

        if let item = items[index] as? T {
            return item
        } else {
            throw error("Item at index \(index) is not of type \(T.self).")
        }
    }
}

public protocol SecureBytePackable {
    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
}

extension SecureBytePackable where Self: FixedWidthInteger {
    public init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        self = try data.withUnsafeBytes { buffer in
            let expectedSize = MemoryLayout<Self>.size
            guard buffer.count == expectedSize else {
                throw error(
                    "Buffer is the wrong size. Expected: \(expectedSize) Got: \(buffer.count)"
                )
            }
            return buffer.load(as: Self.self).bigEndian
        }
    }

    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        var value = self.bigEndian
        let data = Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
        return try data.withUnsafeBytes(body)
    }
}

extension SizeBytes where Self: FixedWidthInteger {
    public static var sizeBytes: Int {
        MemoryLayout<Self>.size
    }
}

extension SymmetricKey: SecureBytePackable {}
extension Curve25519.Signing.PrivateKey: SecureBytePackable {}
extension Curve25519.KeyAgreement.PrivateKey: SecureBytePackable {}
extension Kyber1024.PrivateKey: SecureBytePackable {}
extension Int: SecureBytePackable, SizeBytes {}
extension Int16: SecureBytePackable, SizeBytes {}
extension Int32: SecureBytePackable, SizeBytes {}
extension Int64: SecureBytePackable, SizeBytes {}
extension Int8: SecureBytePackable, SizeBytes {}
extension UInt: SecureBytePackable, SizeBytes {}
extension UInt16: SecureBytePackable, SizeBytes {}
extension UInt32: SecureBytePackable, SizeBytes {}
extension UInt64: SecureBytePackable, SizeBytes {}
extension UInt8: SecureBytePackable, SizeBytes {}

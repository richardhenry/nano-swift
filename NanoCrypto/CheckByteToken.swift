//
//  CheckByteToken.swift
//  NanoCrypto
//
//  Created by Richard Henry on 1/9/24.
//

import CRC
import CryptoKit
import Foundation
import NanoCore

public struct CheckByteToken {
    var bytes: SecureBytes

    public var rawValue: Data {
        Data(bytes)
    }

    public var symmetricKey: SymmetricKey {
        bytes.withUnsafeBytes { bytes in
            SymmetricKey(data: bytes)
        }
    }

    public var checkByte: UInt8 {
        bytes.withUnsafeBytes { bytes in
            CRC8.default.calculate(for: bytes)
        }
    }

    public var combinedValue: Data {
        let secureBytes = SecureBytes(unsafeUninitializedCapacity: 33) { outPtr, outBytes in
            bytes.withUnsafeBytes { keyPtr in
                outPtr.copyMemory(from: keyPtr)
            }
            outPtr.baseAddress!.advanced(by: 32).assumingMemoryBound(to: UInt8.self).pointee =
                checkByte
            outBytes = 33
        }

        return Data(secureBytes)
    }

    public init() {
        bytes = SecureBytes(randomBytes: 32)
    }

    public init<D>(rawValue: D) throws where D: ContiguousBytes {
        try rawValue.withUnsafeBytes { bytes in
            guard bytes.count == 32 else {
                throw error("Wrong number of bytes.")
            }
        }

        bytes = SecureBytes(bytes: rawValue)
    }

    public init(symmetricKey: SymmetricKey) throws {
        guard symmetricKey.bitCount == 256 else {
            throw error("Key size is incorrect.")
        }

        bytes = symmetricKey.withUnsafeBytes { bytes in
            SecureBytes(bytes: bytes)
        }
    }

    public init<D>(combinedValue: D) throws where D: ContiguousBytes {
        bytes = try combinedValue.withUnsafeBytes { dataPtr in
            guard dataPtr.count == 33 else {
                throw error("Wrong number of bytes.")
            }

            return SecureBytes(unsafeUninitializedCapacity: 32) { outPtr, outBytes in
                dataPtr.copyBytes(to: outPtr, count: 32)
                outBytes = 32
            }
        }

        try combinedValue.withUnsafeBytes { dataPtr in
            let checkByte = dataPtr.baseAddress!.advanced(by: 32)
                .assumingMemoryBound(
                    to: UInt8.self
                )
                .pointee
            try bytes.withUnsafeBytes { bytes in
                try CRC8.default.verify(checkByte, for: bytes)
            }
        }
    }
}

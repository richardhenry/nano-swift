//
//  InsecureCodableSymmetricKey.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/19/24.
//

import CryptoKit
import Foundation

/// This wrapper around symmetric key adds codable conformance. You MUST read the following documentation before using this interface.
///
/// This is implemented as a wrapper rather than as an extension because this interface should be used very carefully. It is not possible to use secure memory for coding without having complete control over the encoder and decoder, so using this interface means that key material will leak out of secure memory during coding.
///
/// Currently we only use this for message attachment keys, which is acceptable because a) the scope of the key is limited to a single attachment; b) the attachment plaintext ends up in memory when it is viewed; c) the attachment key must be encoded along with the rest of the message plaintext one way or another; and d) attachment keys are stored in SQLite for practical reasons, which uses encrypted files on disk but doesn't use secure memory.
///
/// This interface should NEVER be used for epoch root keys, user keys, etc.
///
public struct InsecureCodableSymmetricKey: RawRepresentable, Codable {
    public var rawValue: SymmetricKey

    /// Create a codable wrapper around a symmetric key. You MUST read the documentation for this struct before using this interface.
    public init(rawValue: SymmetricKey) {
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        // In a release build, data is a reference rather than a copy, so don't zero it.
        // Doing so will cause a crash.
        let data = try decoder.singleValueContainer().decode(Data.self)
        self = .init(rawValue: SymmetricKey(data: data))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try rawValue.withUnsafeBytes { bytes in
            try container.encode(Data(bytes))
        }
    }
}

extension InsecureCodableSymmetricKey: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        // The underlying comparison is constant time.
        lhs.rawValue == rhs.rawValue
    }
}

//
//  PublicKeyCodable.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/19/24.
//

import CryptoKit
import Foundation

public protocol PublicKeyCodable: CryptoRawRepresentable, Codable {}

extension PublicKeyCodable {
    public init(from decoder: any Decoder) throws {
        let data = try decoder.singleValueContainer().decode(Data.self)
        self = try .init(rawRepresentation: data)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawRepresentation)
    }
}

extension Curve25519.Signing.PublicKey: PublicKeyCodable {}
extension Curve25519.KeyAgreement.PublicKey: PublicKeyCodable {}
extension Kyber1024.PublicKey: PublicKeyCodable {}

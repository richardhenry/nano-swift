//
//  KeyEquatable.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/19/24.
//

import CryptoKit
import Foundation

public protocol KeyEquatable: CryptoRawRepresentable, Equatable {}

extension KeyEquatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        safeCompare(lhs.rawRepresentation, rhs.rawRepresentation)
    }
}

extension Curve25519.Signing.PrivateKey: KeyEquatable {}
extension Curve25519.Signing.PublicKey: KeyEquatable {}
extension Curve25519.KeyAgreement.PrivateKey: KeyEquatable {}
extension Curve25519.KeyAgreement.PublicKey: KeyEquatable {}

extension Kyber1024.PrivateKey: KeyEquatable {}
extension Kyber1024.PublicKey: KeyEquatable {}

//
//  SizeBytes.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/20/24.
//

import CryptoKit
import Foundation

public protocol SizeBytes {
    static var sizeBytes: Int { get }
}

extension Curve25519.KeyAgreement.PrivateKey: SizeBytes {
    public static var sizeBytes: Int { 32 }
}

extension Curve25519.KeyAgreement.PublicKey: SizeBytes {
    public static var sizeBytes: Int { 32 }
}

extension Curve25519.Signing.PrivateKey: SizeBytes {
    public static var sizeBytes: Int { 32 }
}

extension Curve25519.Signing.PublicKey: SizeBytes {
    public static var sizeBytes: Int { 32 }
}

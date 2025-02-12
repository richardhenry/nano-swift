//
//  KeychainValue.swift
//  NanoCrypto
//
//  Created by Richard Henry on 5/14/24.
//

import CryptoKit
import Foundation

public protocol KeychainValue: CryptoRawRepresentable {}

extension Curve25519.Signing.PrivateKey: KeychainValue {}
extension Curve25519.KeyAgreement.PrivateKey: KeychainValue {}
extension SymmetricKey: KeychainValue {}
extension Kyber1024.PrivateKey: KeychainValue {}

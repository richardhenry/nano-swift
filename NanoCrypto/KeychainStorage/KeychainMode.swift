//
//  KeychainMode.swift
//  NanoCrypto
//
//  Created by Richard Henry on 5/14/24.
//

import Foundation

public enum KeychainMode: CaseIterable {
    /// The single device local keychain is used.
    case local
    /// The iCloud keychain is used.
    case cloud

    var keychainAccessible: CFString {
        switch self {
        case .local:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .cloud:
            return kSecAttrAccessibleAfterFirstUnlock
        }
    }

    var keychainSynchronizable: Bool {
        switch self {
        case .local:
            return false
        case .cloud:
            return true
        }
    }
}

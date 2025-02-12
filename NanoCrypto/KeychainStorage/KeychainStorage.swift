//
//  KeychainStorage.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/19/24.
//

import Foundation
import NanoCore

public struct KeychainStorage {
    private let backing: KeychainBacking

    /// Returns keychain storage provided by the operating system.
    public static let shared: KeychainStorage = {
        Self.init(
            backing: SystemBacking(
                keychainService: "com.nanochat.Nano",
                keychainAccessGroup: "3A7G76WUUR.group.nanochat.Nano"
            )
        )
    }()

    /// Returns ephemeral mock keychain storage, suitable for unit testing.
    public static func ephemeral() -> KeychainStorage {
        self.init(backing: TemporaryBacking())
    }

    public func get<T: KeychainValue>(account: String, mode: KeychainMode) throws -> T {
        try backing.get(account: account, mode: mode)
    }

    public func exists(account: String, mode: KeychainMode) throws -> Bool {
        try backing.exists(account: account, mode: mode)
    }

    public func save(_ value: KeychainValue, account: String, mode: KeychainMode) throws {
        try backing.save(value: value, account: account, mode: mode)
    }

    public func delete(account: String, mode: KeychainMode) throws {
        try backing.delete(account: account, mode: mode)
    }

    public func deleteAll(mode: KeychainMode) throws {
        try backing.deleteAll(mode: mode)
    }
}

// MARK: - Keychain Backing

private protocol KeychainBacking {
    func get<T: KeychainValue>(account: String, mode: KeychainMode) throws -> T
    func exists(account: String, mode: KeychainMode) throws -> Bool
    func save(value: KeychainValue, account: String, mode: KeychainMode) throws
    func delete(account: String, mode: KeychainMode) throws
    func deleteAll(mode: KeychainMode) throws
}

private struct SystemBacking: KeychainBacking {
    let keychainService: String
    let keychainAccessGroup: String

    func get<T: KeychainValue>(account: String, mode: KeychainMode) throws -> T {
        let data = try get(account: account, mode: mode)
        return try T.init(rawRepresentation: data)
    }

    func get(account: String, mode: KeychainMode) throws -> Data {
        var result: AnyObject?

        let status = SecItemCopyMatching(
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: keychainService,
                kSecAttrAccessGroup: keychainAccessGroup,
                kSecAttrAccount: account,
                kSecAttrAccessible: mode.keychainAccessible,
                kSecUseDataProtectionKeychain: true,
                kSecAttrSynchronizable: mode.keychainSynchronizable,
                kSecReturnAttributes: false,
                kSecReturnData: true,
                kSecMatchLimit: kSecMatchLimitOne,
            ] as CFDictionary,
            &result
        )

        switch status {
        case errSecSuccess:
            if let data = result as? Data {
                return data
            } else {
                throw error("Unable to decode data from item: \(account)", as: KeychainError.self)
            }
        case errSecInteractionNotAllowed:
            fatalError(
                "Keychain is not available, likely because the device has not yet been unlocked."
            )
        default:
            throw KeychainError(status)
        }
    }

    func exists(account: String, mode: KeychainMode) throws -> Bool {
        do {
            _ = try get(account: account, mode: mode)
            return true
        } catch let error as KeychainError {
            if error.doesNotExist {
                return false
            } else {
                throw error
            }
        }
    }

    func save(value: any KeychainValue, account: String, mode: KeychainMode) throws {
        let status = SecItemAdd(
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: keychainService,
                kSecAttrAccessGroup: keychainAccessGroup,
                kSecAttrAccount: account,
                kSecAttrAccessible: mode.keychainAccessible,
                kSecUseDataProtectionKeychain: true,
                kSecAttrSynchronizable: mode.keychainSynchronizable,
                kSecValueData: value.rawRepresentation,
            ] as CFDictionary,
            nil
        )

        switch status {
        case errSecSuccess, errSecDuplicateItem:
            break
        case errSecInteractionNotAllowed:
            fatalError(
                "Keychain is not available, likely because the device has not yet been unlocked."
            )
        default:
            throw KeychainError(status)
        }
    }

    func delete(account: String, mode: KeychainMode) throws {
        let status = SecItemDelete(
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: keychainService,
                kSecAttrAccessGroup: keychainAccessGroup,
                kSecAttrAccount: account,
                kSecAttrAccessible: mode.keychainAccessible,
                kSecUseDataProtectionKeychain: true,
                kSecAttrSynchronizable: mode.keychainSynchronizable,
            ] as CFDictionary
        )

        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            log(.warning, "Unable to delete, item not found: \(account) Mode: \(mode)")
        case errSecInteractionNotAllowed:
            fatalError(
                "Keychain is not available, likely because the device has not yet been unlocked."
            )
        default:
            throw KeychainError(status)
        }
    }

    func deleteAll(mode: KeychainMode) throws {
        let status = SecItemDelete(
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: keychainService,
                kSecAttrAccessGroup: keychainAccessGroup,
                kSecAttrAccessible: mode.keychainAccessible,
                kSecUseDataProtectionKeychain: true,
                kSecAttrSynchronizable: mode.keychainSynchronizable,
            ] as CFDictionary
        )

        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            log(.warning, "Unable to delete all, item not found. Mode: \(mode)")
        case errSecInteractionNotAllowed:
            fatalError(
                "Keychain is not available, likely because the device has not yet been unlocked."
            )
        default:
            throw KeychainError(status)
        }
    }
}

private class TemporaryBacking: KeychainBacking {
    var storage: [KeychainMode: [String: KeychainValue]] = {
        var new = [KeychainMode: [String: KeychainValue]]()
        for mode in KeychainMode.allCases {
            new[mode] = [:]
        }
        return new
    }()

    func get<T: KeychainValue>(account: String, mode: KeychainMode) throws -> T {
        if let value = storage[mode]![account] as? T {
            return value
        } else {
            throw KeychainError(errSecItemNotFound)
        }
    }

    func exists(account: String, mode: KeychainMode) throws -> Bool {
        storage[mode]![account] != nil
    }

    func save(value: any KeychainValue, account: String, mode: KeychainMode) throws {
        storage[mode]![account] = value
    }

    func delete(account: String, mode: KeychainMode) throws {
        storage[mode]!.removeValue(forKey: account)
    }

    func deleteAll(mode: KeychainMode) throws {
        storage[mode]!.removeAll()
    }
}

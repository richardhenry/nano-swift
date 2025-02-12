//
//  KeychainItem.swift
//  NanoKit
//
//  Created by Richard Henry on 3/19/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public enum KeychainItem {
    case ephemeralRecoveryKey(UserID)
    case recoveryKey(UserID)
    case userSigningKey(UserID)
    case epochRootKey(EpochID)
    case memberStoreKey(UserID, GroupID)
    case memberStoreKeyKyber(UserID, GroupID)
    case memberAuthKey(UserID, GroupID)
    case inviteSecretKey(VirtualMemberID)

    var account: String {
        switch self {
        case .ephemeralRecoveryKey(let userId):
            return "ephemeral-recovery-key:\(userId)"
        case .recoveryKey(let userId):
            return "recovery-key:\(userId)"
        case .userSigningKey(let userId):
            return "user-signing-key:\(userId)"
        case .epochRootKey(let epochId):
            return "epoch-root-key:\(epochId)"
        case .memberStoreKey(let userId, let groupId):
            return "member-store-key:\(userId):\(groupId)"
        case .memberStoreKeyKyber(let userId, let groupId):
            return "member-store-key-kyber:\(userId):\(groupId)"
        case .memberAuthKey(let userId, let groupId):
            return "member-auth-key:\(userId):\(groupId)"
        case .inviteSecretKey(let virtualId):
            return "invite-secret-key:\(virtualId)"
        }
    }

    var mode: KeychainMode {
        switch self {
        case .ephemeralRecoveryKey:
            return .cloud
        case .recoveryKey:
            return .local
        case .userSigningKey:
            return .local
        case .epochRootKey:
            return .local
        case .memberStoreKey:
            return .local
        case .memberStoreKeyKyber:
            return .local
        case .memberAuthKey:
            return .local
        case .inviteSecretKey:
            return .local
        }
    }
}

extension KeychainStorage {
    public func save(_ value: KeychainValue, to item: KeychainItem) throws {
        log(.debug, "\(self) - Save: \(item)")
        try save(value, account: item.account, mode: item.mode)
    }

    public func get<T: KeychainValue>(_ item: KeychainItem) throws -> T {
        log(.debug, "\(self) - Get: \(item)")
        return try get(account: item.account, mode: item.mode)
    }

    public func exists(_ item: KeychainItem) throws -> Bool {
        log(.debug, "\(self) - Exists: \(item)")
        return try exists(account: item.account, mode: item.mode)
    }

    public func delete(_ item: KeychainItem) throws {
        log(.debug, "\(self) - Delete: \(item)")
        try delete(account: item.account, mode: item.mode)
    }
}

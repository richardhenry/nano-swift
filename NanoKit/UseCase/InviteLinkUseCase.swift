//
//  InviteLinkUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 3/21/24.
//

import CryptoKit
import Foundation
import NanoCrypto

public struct InviteLinkUseCase {
    public static let baseURL = URL(string: <#T##"https://example.com/invite/"##String#>)!
    public var keychainStorage: KeychainStorage

    public init(keychainStorage: KeychainStorage = .shared) {
        self.keychainStorage = keychainStorage
    }

    public func urlString(from invite: InviteModel) throws -> String {
        let secretKey: SymmetricKey = try keychainStorage.get(.inviteSecretKey(invite.virtualId))
        return try Self.urlString(from: invite, secretKey: secretKey)
    }

    public static func urlString(from invite: InviteModel, secretKey: SymmetricKey) throws -> String
    {
        let tokenString = try CheckByteToken(rawValue: invite.token).urlSafeBase64EncodedString
        let secretKeyString = try CheckByteToken(symmetricKey: secretKey).urlSafeBase64EncodedString
        return Self.baseURL.appending(component: tokenString).absoluteString + "#" + secretKeyString
    }
}

//
//  SignedPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 3/22/24.
//

import CryptoKit
import Foundation
import GRDB
import NanoCore

public protocol SignedPayload {
    var signature: Data { get }
    var timestamp: Timestamp { get }
    var signedData: Data { get throws }
    var signingUserId: UserID { get }
    func validateSignature(with userKey: UserKeyModel) throws
}

extension SignedPayload {
    public func fetchSigningKey(_ db: Database) throws -> UserKeyModel {
        try UserKeyModel.fetchExpect(db, id: signingUserId)
    }

    public func validateSignature(with userKey: UserKeyModel) throws {
        guard userKey.id == signingUserId else {
            throw error("User ID does not match. Expected: \(signingUserId) Got: \(userKey.id)")
        }

        guard userKey.signing.isValidSignature(signature, for: try signedData) else {
            throw error("Signature is not valid.")
        }
    }
}

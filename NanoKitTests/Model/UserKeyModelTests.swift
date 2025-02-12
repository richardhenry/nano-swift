//
//  UserKeyModelTests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 3/20/24.
//

import CryptoKit
import NanoCore
import XCTest

@testable import NanoKit

final class UserKeyModelTests: XCTestCase {
    func testUserKeySaveNotAllowed() throws {
        let dataStore = DataStore.ephemeral()

        let k0 = UserKeyModel(
            id: UserID(),
            signing: Curve25519.Signing.PrivateKey().publicKey,
            timestamp: 1_704_696_536_048
        )

        try dataStore.write { db in
            // save() is not allowed
            XCTAssertThrowsError(try k0.save(db))
        }
    }
}

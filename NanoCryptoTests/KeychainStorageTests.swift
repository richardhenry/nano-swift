//
//  KeychainStorageTests.swift
//  NanoCryptoTests
//
//  Created by Richard Henry on 3/19/24.
//

import CryptoKit
import XCTest

@testable import NanoCrypto

final class KeychainStorageTests: XCTestCase {
    func testEphemeral() throws {
        let storage = KeychainStorage.ephemeral()

        let k = SymmetricKey(size: .bits256)

        try storage.save(k, account: "test123", mode: .local)

        XCTAssertEqual(try storage.get(account: "test123", mode: .local), k)

        try storage.delete(account: "test123", mode: .local)

        XCTAssertThrowsError(try storage.get(account: "test123", mode: .local) as SymmetricKey)

        try storage.save(k, account: "test123", mode: .local)

        XCTAssertEqual(try storage.get(account: "test123", mode: .local), k)

        let k1 = SymmetricKey(size: .bits256)

        try storage.save(k1, account: "test123", mode: .local)

        XCTAssertEqual(try! storage.get(account: "test123", mode: .local), k1)

        try storage.deleteAll(mode: .local)

        XCTAssertThrowsError(try storage.get(account: "test123", mode: .local) as SymmetricKey)
    }
}

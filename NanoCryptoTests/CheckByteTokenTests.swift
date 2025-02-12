//
//  CheckByteTokenTests.swift
//  NanoCryptoTests
//
//  Created by Richard Henry on 3/19/24.
//

import CryptoKit
import XCTest

@testable import NanoCrypto

final class CheckByteTokenTests: XCTestCase {
    func testCheckByteToken() throws {
        let d0 = Data(base64Encoded: "gC8fSQlflqacKjP4pEzwgGvmF43LYhzDyhwrb/7EN7o=")!
        let d1 = Data(base64Encoded: "4fpY0rbMPqsTdl+Kn4BTnFgnfyd53uzAtGfAftbLh6Q=")!

        let cb0 = try CheckByteToken(rawValue: d0)
        XCTAssertEqual(cb0.rawValue, d0)
        XCTAssertEqual(cb0.symmetricKey, SymmetricKey(data: d0))
        XCTAssertEqual(cb0.checkByte, [UInt8](cb0.combinedValue).last)

        let cb1 = try CheckByteToken(rawValue: d1)
        XCTAssertEqual(cb1.rawValue, d1)
        XCTAssertEqual(cb1.symmetricKey, SymmetricKey(data: d1))
        XCTAssertEqual(cb1.checkByte, [UInt8](cb1.combinedValue).last)

        XCTAssertEqual(
            cb0.combinedValue,
            Data(base64Encoded: "gC8fSQlflqacKjP4pEzwgGvmF43LYhzDyhwrb/7EN7qe")!
        )

        XCTAssertEqual(
            cb1.combinedValue,
            Data(base64Encoded: "4fpY0rbMPqsTdl+Kn4BTnFgnfyd53uzAtGfAftbLh6RQ")!
        )

        let cb0_a = try CheckByteToken(combinedValue: cb0.combinedValue)
        XCTAssertEqual(cb0.combinedValue, cb0_a.combinedValue)

        let cb1_a = try CheckByteToken(combinedValue: cb1.combinedValue)
        XCTAssertEqual(cb1.combinedValue, cb1_a.combinedValue)

        let cb0_b = try CheckByteToken(symmetricKey: SymmetricKey(data: d0))
        XCTAssertEqual(cb0.combinedValue, cb0_b.combinedValue)

        let cb1_b = try CheckByteToken(symmetricKey: SymmetricKey(data: d1))
        XCTAssertEqual(cb1.combinedValue, cb1_b.combinedValue)
    }

    func testVerifyFailed() throws {
        let x = Data(randomBytes: 33)
        XCTAssertThrowsError(try CheckByteToken(combinedValue: x))
    }

    func testCombinedIncorrectSize() throws {
        let x = Data(randomBytes: 32)
        XCTAssertThrowsError(try CheckByteToken(combinedValue: x))
    }

    func testRawIncorrectSize() throws {
        let x = Data(randomBytes: 31)
        XCTAssertThrowsError(try CheckByteToken(rawValue: x))
    }

    func testSymmetricKeyIncorrectSize() throws {
        let x = SymmetricKey(size: .bits192)
        XCTAssertThrowsError(try CheckByteToken(symmetricKey: x))
    }
}

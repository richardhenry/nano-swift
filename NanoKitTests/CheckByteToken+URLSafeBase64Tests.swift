//
//  CheckByteTokenTests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 1/9/24.
//

import NanoCrypto
import XCTest

@testable import NanoKit

final class CheckByteTokenURLSafeBase64Tests: XCTestCase {
    func testCheckByteTokenURLSafeBase64() throws {
        let d0 = Data(base64Encoded: "gC8fSQlflqacKjP4pEzwgGvmF43LYhzDyhwrb/7EN7o=")!
        let d1 = Data(base64Encoded: "4fpY0rbMPqsTdl+Kn4BTnFgnfyd53uzAtGfAftbLh6Q=")!

        let cb0 = try CheckByteToken(rawValue: d0)
        let cb1 = try CheckByteToken(rawValue: d1)

        let t0 = cb0.urlSafeBase64EncodedString
        XCTAssertEqual(t0, "gC8fSQlflqacKjP4pEzwgGvmF43LYhzDyhwrb_7EN7qe")

        let t1 = cb1.urlSafeBase64EncodedString
        XCTAssertEqual(t1, "4fpY0rbMPqsTdl-Kn4BTnFgnfyd53uzAtGfAftbLh6RQ")

        let cb0_b = try CheckByteToken(string: t0)
        XCTAssertEqual(cb0_b.rawValue, d0)

        let cb1_b = try CheckByteToken(string: t1)
        XCTAssertEqual(cb1_b.rawValue, d1)

        // a single character in this string has changed
        let x0 = "gC8fSQlflqacKjP4pEzwgBvmF43LYhzDyhwrb_7EN7qe"
        XCTAssertThrowsError(try CheckByteToken(string: x0))

        let x1 = "gC8fSQlflqacKjP4pEzwgGvmF43LYhzDywrb_7EN7qe"
        XCTAssertThrowsError(try CheckByteToken(string: x1))

        let x2 = "@ a nonsense string !! "
        XCTAssertThrowsError(try CheckByteToken(string: x2))
    }
}

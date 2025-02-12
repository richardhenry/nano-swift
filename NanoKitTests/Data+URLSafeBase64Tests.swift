//
//  Data+URLSafeBase64Tests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 1/9/24.
//

import XCTest

@testable import NanoKit

final class DataURLSafeBase64Tests: XCTestCase {
    func testURLSafeBase64() throws {
        let d0 = Data(base64Encoded: "7DgxtVSu4srQUG8+UKOOij9KpcEBs+/g4hEFYv3hYA==")!
        let s0 = d0.urlSafeBase64EncodedString()
        XCTAssertEqual(s0, "7DgxtVSu4srQUG8-UKOOij9KpcEBs-_g4hEFYv3hYA")
        XCTAssertEqual(d0, Data(urlSafeBase64EncodedString: s0))

        for size in 0...255 {
            for _ in 0...9 {
                let d1 = Data((0..<size).map { _ in UInt8.random(in: 0...255) })
                let s1 = d1.urlSafeBase64EncodedString()
                XCTAssertEqual(d1, Data(urlSafeBase64EncodedString: s1))
            }
        }
    }
}

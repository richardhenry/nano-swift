//
//  PadmeTests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 3/15/24.
//

import XCTest

@testable import NanoCrypto

final class PadmeTests: XCTestCase {
    func testPaddedSize() throws {
        XCTAssertEqual(Padme.size(for: 0), 0)
        XCTAssertEqual(Padme.size(for: 1), 10)
        XCTAssertEqual(Padme.size(for: 10), 10)
        XCTAssertEqual(Padme.size(for: 97), 104)
        XCTAssertEqual(Padme.size(for: 100), 104)
        XCTAssertEqual(Padme.size(for: 993), 1_024)
        XCTAssertEqual(Padme.size(for: 1_000), 1_024)
        XCTAssertEqual(Padme.size(for: 9_900), 10_240)
        XCTAssertEqual(Padme.size(for: 10_000), 10_240)
        XCTAssertEqual(Padme.size(for: 99_900), 100_352)
        XCTAssertEqual(Padme.size(for: 100_000), 100_352)
        XCTAssertEqual(Padme.size(for: 999_900), 1_015_808)
        XCTAssertEqual(Padme.size(for: 1_000_000), 1_015_808)
        XCTAssertEqual(Padme.size(for: 9_999_900), 10_223_616)
        XCTAssertEqual(Padme.size(for: 10_000_000), 10_223_616)
        XCTAssertEqual(Padme.size(for: 99_999_900), 100_663_296)
        XCTAssertEqual(Padme.size(for: 100_000_000), 100_663_296)
        XCTAssertEqual(Padme.size(for: 999_999_900), 1_006_632_960)
        XCTAssertEqual(Padme.size(for: 1_000_000_000), 1_006_632_960)
        XCTAssertEqual(Padme.size(for: 9_999_999_900), 10_066_329_600)
        XCTAssertEqual(Padme.size(for: 10_000_000_000), 10_066_329_600)
    }

    func testPad() throws {
        try validatePad(size: 1)
        try validatePad(size: 10)
        try validatePad(size: 100)
        try validatePad(size: 1_000)
        try validatePad(size: 10_000)
        try validatePad(size: 100_000)
        try validatePad(size: 1_000_000)
        try validatePad(size: 10_000_000)
        try validatePad(size: 100_000_000)
    }

    func testSmallPadPerformance() throws {
        let originalData = Data(randomBytes: 10_000)

        measure {
            _ = try! Padme.pad(originalData: originalData)
        }
    }

    func testLargePadPerformance() throws {
        let originalData = Data(randomBytes: 100_000_000)

        measure {
            _ = try! Padme.pad(originalData: originalData)
        }
    }

    func testSmallUnpadPerformance() throws {
        let paddedData = try Padme.pad(originalData: Data(randomBytes: 10_000))

        measure {
            _ = try! Padme.unpad(paddedData: paddedData)
        }
    }

    func testLargeUnpadPerformance() throws {
        let paddedData = try Padme.pad(originalData: Data(randomBytes: 100_000_000))

        measure {
            _ = try! Padme.unpad(paddedData: paddedData)
        }
    }

    func validatePad(size: Int) throws {
        let originalData = Data(randomBytes: size)
        let paddedData = try Padme.pad(originalData: originalData)

        let paddedSize = Int(Padme.size(for: UInt64(size)))
        XCTAssertEqual(paddedData.count, paddedSize + 4)

        let unpaddedData = try Padme.unpad(paddedData: paddedData)
        XCTAssertEqual(originalData, unpaddedData)
    }

    func testHeaderUInt32Zero() throws {
        let header = Padme.header(originalSize: UInt32(0))
        XCTAssertEqual(header.count, 4)
        XCTAssertEqual(try Padme.loadSize(fromHeader: header), UInt32(0))
    }

    func testHeaderUInt3210K() throws {
        let header = Padme.header(originalSize: UInt32(10_000))
        XCTAssertEqual(header.count, 4)
        XCTAssertEqual(try Padme.loadSize(fromHeader: header), UInt32(10_000))
    }

    func testHeaderUInt32Max() throws {
        let header = Padme.header(originalSize: UInt32.max)
        XCTAssertEqual(header.count, 4)
        XCTAssertEqual(try Padme.loadSize(fromHeader: header), UInt32.max)
    }

    func testHeaderUInt64Zero() throws {
        let header = Padme.header(originalSize: UInt64(0))
        XCTAssertEqual(header.count, 8)
        XCTAssertEqual(try Padme.loadSize(fromHeader: header), UInt64(0))
    }

    func testHeaderUInt6410K() throws {
        let header = Padme.header(originalSize: UInt64(10_000))
        XCTAssertEqual(header.count, 8)
        XCTAssertEqual(try Padme.loadSize(fromHeader: header), UInt64(10_000))
    }

    func testHeaderUInt64Max() throws {
        let header = Padme.header(originalSize: UInt64.max)
        XCTAssertEqual(header.count, 8)
        XCTAssertEqual(try Padme.loadSize(fromHeader: header), UInt64.max)
    }
}

//
//  PadmeFileStreamTests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 3/16/24.
//

import XCTest

@testable import NanoCrypto

final class PadmeFileStreamTests: XCTestCase {
    var testDirectory: URL!

    override func setUpWithError() throws {
        super.setUp()
        let tempDirectory = FileManager.default.temporaryDirectory
        let directoryName = UUID().uuidString
        let directoryURL = tempDirectory.appendingPathComponent(directoryName)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        testDirectory = directoryURL
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: testDirectory)
        testDirectory = nil
        super.tearDown()
    }

    func testPadUnpad() throws {
        try validatePadUnpad(with: Data("Hello World!".utf8))
        try validatePadUnpad(with: Data())
        try validatePadUnpad(with: Data(randomBytes: 1))
        try validatePadUnpad(with: Data(randomBytes: 10))
        try validatePadUnpad(with: Data(randomBytes: 100))
        try validatePadUnpad(with: Data(randomBytes: 1_000))
        try validatePadUnpad(with: Data(randomBytes: 10_000))
        try validatePadUnpad(with: Data(randomBytes: 100_000))
        try validatePadUnpad(with: Data(randomBytes: 1_000_000))
        try validatePadUnpad(with: Data(randomBytes: 10_000_000))
        try validatePadUnpad(with: Data(randomBytes: 100_000_000))
    }

    func validatePadUnpad(with originalData: Data) throws {
        let id = UUID().uuidString

        let originalURL = testDirectory.appendingPathComponent("\(id)-original.bin")
        let paddedURL = testDirectory.appendingPathComponent("\(id)-padded.bin")
        let unpaddedURL = testDirectory.appendingPathComponent("\(id)-unpadded.bin")

        try originalData.write(to: originalURL)

        try PadmeFileStream().pad(source: originalURL, target: paddedURL)

        let paddedData = try Data(contentsOf: paddedURL)

        // Check that the padded size is correct
        XCTAssertEqual(UInt64(paddedData.count), 8 + Padme.size(for: UInt64(originalData.count)))

        // Check that the header is correct
        XCTAssertEqual(
            try Padme.loadSize(fromHeader: paddedData.subdata(in: 0..<8)),
            UInt64(originalData.count)
        )

        // Check that the original data is intact
        XCTAssertEqual(originalData, paddedData.subdata(in: 8..<8 + originalData.count))

        // Check that the padding is null padding
        XCTAssertEqual(
            paddedData.subdata(in: 8 + originalData.count..<paddedData.count),
            Data(repeating: 0, count: paddedData.count - originalData.count - 8)
        )

        try PadmeFileStream().unpad(source: paddedURL, target: unpaddedURL)

        let unpaddedData = try Data(contentsOf: unpaddedURL)

        XCTAssertEqual(originalData, unpaddedData)
    }

    func testPadPerformance() throws {
        let id = UUID().uuidString

        let originalURL = testDirectory.appendingPathComponent("\(id)-original.bin")
        let paddedURL = testDirectory.appendingPathComponent("\(id)-padded.bin")

        try Data(randomBytes: 10_000_000).write(to: originalURL)

        measure {
            try! PadmeFileStream().pad(source: originalURL, target: paddedURL)
        }
    }

    func testUnpadPerformance() throws {
        let id = UUID().uuidString

        let originalURL = testDirectory.appendingPathComponent("\(id)-original.bin")
        let paddedURL = testDirectory.appendingPathComponent("\(id)-padded.bin")
        let unpaddedURL = testDirectory.appendingPathComponent("\(id)-unpadded.bin")

        try Data(randomBytes: 10_000_000).write(to: originalURL)
        try PadmeFileStream().pad(source: originalURL, target: paddedURL)

        measure {
            try! PadmeFileStream().unpad(source: paddedURL, target: unpaddedURL)
        }
    }

    func testSpecifiedFileSize() throws {
        let id = UUID().uuidString

        let originalURL = testDirectory.appendingPathComponent("\(id)-original.bin")
        let paddedURL = testDirectory.appendingPathComponent("\(id)-padded.bin")

        try Data(randomBytes: 10_000).write(to: originalURL)

        try PadmeFileStream().pad(source: originalURL, target: paddedURL, sourceSize: 10_000)
    }

    func testFileSizeMismatchError() throws {
        let id = UUID().uuidString

        let originalURL = testDirectory.appendingPathComponent("\(id)-original.bin")
        let paddedURL = testDirectory.appendingPathComponent("\(id)-padded.bin")

        try Data(randomBytes: 10_000).write(to: originalURL)

        XCTAssertThrowsError(
            try PadmeFileStream().pad(source: originalURL, target: paddedURL, sourceSize: 10_001)
        )
    }

    func testOverwriteExisting() throws {
        let id = UUID().uuidString

        let originalURL = testDirectory.appendingPathComponent("\(id)-original.bin")
        let paddedURL = testDirectory.appendingPathComponent("\(id)-padded.bin")
        let unpaddedURL = testDirectory.appendingPathComponent("\(id)-unpadded.bin")

        try Data(randomBytes: 10_000).write(to: originalURL)

        try PadmeFileStream().pad(source: originalURL, target: paddedURL)
        try PadmeFileStream().pad(source: originalURL, target: paddedURL)

        try PadmeFileStream().unpad(source: paddedURL, target: unpaddedURL)
        try PadmeFileStream().unpad(source: paddedURL, target: unpaddedURL)
    }

    func testUnexpectedEndOfFile() throws {
        let id = UUID().uuidString

        let originalData = Data(randomBytes: 10_000)

        let originalURL = testDirectory.appendingPathComponent("\(id)-original.bin")
        let paddedURL = testDirectory.appendingPathComponent("\(id)-padded.bin")
        let unpaddedURL = testDirectory.appendingPathComponent("\(id)-unpadded.bin")

        try originalData.write(to: originalURL)

        try PadmeFileStream().pad(source: originalURL, target: paddedURL)

        let badHeader = Padme.header(originalSize: UInt64(20_000))
        overwritePadHeader(of: paddedURL, with: badHeader)

        let paddedData = try Data(contentsOf: paddedURL)

        // Check that the padded size is correct
        XCTAssertEqual(UInt64(paddedData.count), 8 + Padme.size(for: UInt64(originalData.count)))

        // Check that the header is the corrupted value
        XCTAssertEqual(
            try Padme.loadSize(fromHeader: paddedData.subdata(in: 0..<8)),
            UInt64(20_000)
        )

        // Check that the original data is intact
        XCTAssertEqual(originalData, paddedData.subdata(in: 8..<8 + originalData.count))

        // Check that the padding is null padding
        XCTAssertEqual(
            paddedData.subdata(in: 8 + originalData.count..<paddedData.count),
            Data(repeating: 0, count: paddedData.count - originalData.count - 8)
        )

        XCTAssertThrowsError(try PadmeFileStream().unpad(source: paddedURL, target: unpaddedURL))
    }

    func overwritePadHeader(of sourceURL: URL, with data: Data) {
        assert(data.count == 8)
        let file = fopen(sourceURL.path, "r+b")!
        defer { fclose(file) }
        fwrite([UInt8](data), 1, data.count, file)
    }
}

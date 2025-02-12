//
//  XChaChaPolyFileStreamTests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 2/10/24.
//

import CryptoKit
import XCTest

@testable import NanoCrypto

final class XChaChaPolyFileStreamTests: XCTestCase {
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

    func testEncryptDecrypt() throws {
        try validateEncryptDecrypt(with: Data("Hello World!".utf8))
        try validateEncryptDecrypt(with: Data())
        try validateEncryptDecrypt(with: Data(randomBytes: 1))
        try validateEncryptDecrypt(with: Data(randomBytes: 10))
        try validateEncryptDecrypt(with: Data(randomBytes: 100))
        try validateEncryptDecrypt(with: Data(randomBytes: 1_000))
        try validateEncryptDecrypt(with: Data(randomBytes: 10_000))
        try validateEncryptDecrypt(with: Data(randomBytes: 100_000))
        try validateEncryptDecrypt(with: Data(randomBytes: 1_000_000))
        try validateEncryptDecrypt(with: Data(randomBytes: 10_000_000))
        try validateEncryptDecrypt(with: Data(randomBytes: 100_000_000))
    }

    func validateEncryptDecrypt(with plaintext: Data) throws {
        let id = UUID().uuidString

        let originalURL = testDirectory.appendingPathComponent("\(id)-original.bin")
        let encryptedURL = testDirectory.appendingPathComponent("\(id)-encrypted.enc")
        let decryptedURL = testDirectory.appendingPathComponent("\(id)-decrypted.bin")

        try plaintext.write(to: originalURL)

        let key = SymmetricKey(size: .bits256)
        let streamCipher = XChaChaPolyFileStream()

        try streamCipher.encrypt(source: originalURL, target: encryptedURL, key: key)
        try streamCipher.decrypt(source: encryptedURL, target: decryptedURL, key: key)

        let decryptedContent = try Data(contentsOf: decryptedURL)
        XCTAssertEqual(decryptedContent, plaintext)

        // sanity check
        XCTAssertNotEqual(try Data(contentsOf: encryptedURL), plaintext)
    }

    func testWrongKey() throws {
        let id = UUID().uuidString

        let originalURL = testDirectory.appendingPathComponent("\(id)-original.bin")
        let encryptedURL = testDirectory.appendingPathComponent("\(id)-encrypted.enc")
        let decryptedURL = testDirectory.appendingPathComponent("\(id)-decrypted.bin")

        try Data(randomBytes: 1_000_000).write(to: originalURL)

        let streamCipher = XChaChaPolyFileStream()

        try streamCipher.encrypt(
            source: originalURL,
            target: encryptedURL,
            key: SymmetricKey(size: .bits256)
        )

        XCTAssertThrowsError(
            try streamCipher.decrypt(
                source: encryptedURL,
                target: decryptedURL,
                key: SymmetricKey(size: .bits256)
            )
        )
    }

    func testEncryptPerformance() throws {
        let ctx = UUID().uuidString

        let originalURL = testDirectory.appendingPathComponent("\(ctx)-original.bin")
        let encryptedURL = testDirectory.appendingPathComponent("\(ctx)-encrypted.enc")

        try Data(randomBytes: 10_000_000).write(to: originalURL)

        let key = SymmetricKey(size: .bits256)
        let streamCipher = XChaChaPolyFileStream()

        measure {
            try! streamCipher.encrypt(source: originalURL, target: encryptedURL, key: key)
        }
    }

    func testDecryptPerformance() throws {
        let ctx = UUID().uuidString

        let originalURL = testDirectory.appendingPathComponent("\(ctx)-original.bin")
        let encryptedURL = testDirectory.appendingPathComponent("\(ctx)-encrypted.enc")
        let decryptedURL = testDirectory.appendingPathComponent("\(ctx)-decrypted.bin")

        try Data(randomBytes: 10_000_000).write(to: originalURL)

        let key = SymmetricKey(size: .bits256)
        let streamCipher = XChaChaPolyFileStream()
        try streamCipher.encrypt(source: originalURL, target: encryptedURL, key: key)

        measure {
            try! streamCipher.encrypt(source: encryptedURL, target: decryptedURL, key: key)
        }
    }
}

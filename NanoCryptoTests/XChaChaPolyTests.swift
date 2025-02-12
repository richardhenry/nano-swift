//
//  XChaChaPolyTests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 3/16/24.
//

import CryptoKit
import XCTest

@testable import NanoCrypto

final class XChaChaPolyTests: XCTestCase {
    func testSealedBox() throws {
        let message = Data(randomBytes: 10_123)
        let key = SymmetricKey(size: .bits256)

        let sealedBox = try XChaChaPoly.seal(message, using: key)

        XCTAssertEqual(sealedBox.ciphertext.count, message.count)
        XCTAssertEqual(sealedBox.tag.count, XChaChaPoly.tagBytes)
        XCTAssertEqual(sealedBox.nonce.data.count, XChaChaPoly.nonceBytes)

        XCTAssertEqual(
            sealedBox.combined.count,
            message.count + XChaChaPoly.tagBytes + XChaChaPoly.nonceBytes
        )
    }

    func testSealedBoxEmpty() throws {
        let message = Data()
        let key = SymmetricKey(size: .bits256)

        let sealedBox = try XChaChaPoly.seal(message, using: key)

        XCTAssertEqual(sealedBox.ciphertext.count, 0)
        XCTAssertEqual(sealedBox.tag.count, XChaChaPoly.tagBytes)
        XCTAssertEqual(sealedBox.nonce.data.count, XChaChaPoly.nonceBytes)

        XCTAssertEqual(sealedBox.combined.count, XChaChaPoly.tagBytes + XChaChaPoly.nonceBytes)
    }

    func testEncryptDecrypt() throws {
        let message = Data(randomBytes: 10_123)
        let key = SymmetricKey(size: .bits256)

        let sealedBox = try XChaChaPoly.seal(message, using: key)
        let decrypted = try XChaChaPoly.open(sealedBox, using: key)

        XCTAssertEqual(message, decrypted)

        XCTAssertThrowsError(try XChaChaPoly.open(sealedBox, using: SymmetricKey(size: .bits256)))
    }

    func testDecryptIntoSecureMemory() throws {
        let message = Data(randomBytes: 10_123)
        let key = SymmetricKey(size: .bits256)

        let sealedBox = try XChaChaPoly.seal(message, using: key)
        // We are not currently validating that this is using SecureBytes in this unit test, but this can be verified by setting a breakpoint and inspecting the deallocator for the data storage. We should add a mock for secure data that allows us to verify this programatically.
        let decrypted = try XChaChaPoly.open(sealedBox, using: key, intoSecureMemory: true)

        XCTAssertEqual(message, decrypted)
    }

    func testEncryptDecryptWrongKey() throws {
        let sealedBox = try XChaChaPoly.seal(
            Data(randomBytes: 10_123),
            using: SymmetricKey(size: .bits256)
        )

        XCTAssertThrowsError(try XChaChaPoly.open(sealedBox, using: SymmetricKey(size: .bits256)))
    }

    func testEncryptDecryptEmptyMessage() throws {
        let key = SymmetricKey(size: .bits256)

        let sealedBox = try XChaChaPoly.seal(Data(), using: key)
        let decrypted = try XChaChaPoly.open(sealedBox, using: key)

        XCTAssertEqual(decrypted.count, 0)
    }

    func testAuthenticatedData() throws {
        let message = Data(randomBytes: 10_123)
        let key = SymmetricKey(size: .bits256)

        let sealedBox = try XChaChaPoly.seal(
            message,
            using: key,
            authenticating: Data("hello 123".utf8)
        )
        let decrypted = try XChaChaPoly.open(
            sealedBox,
            using: key,
            authenticating: Data("hello 123".utf8)
        )

        XCTAssertEqual(message, decrypted)

        XCTAssertThrowsError(
            try XChaChaPoly.open(sealedBox, using: key, authenticating: Data("hello 456".utf8))
        )

        XCTAssertThrowsError(try XChaChaPoly.open(sealedBox, using: key))
    }

    func testNonceSanityCheck() throws {
        XCTAssertNotEqual(XChaChaPoly.Nonce().data, XChaChaPoly.Nonce().data)
        XCTAssertEqual(XChaChaPoly.Nonce().data.count, 24)
    }

    func testWrongKeySize() throws {
        XCTAssertThrowsError(
            try XChaChaPoly.seal(Data(randomBytes: 100), using: SymmetricKey(size: .bits192))
        )
    }

    func testWrongNonceSize() throws {
        XCTAssertThrowsError(try XChaChaPoly.Nonce(data: Data(repeating: 0, count: 12)))

        XCTAssertThrowsError(try XChaChaPoly.Nonce(data: Data(repeating: 0, count: 30)))
    }

    func testWrongCombinedDataSize() throws {
        XCTAssertThrowsError(try XChaChaPoly.SealedBox(combined: Data(repeating: 0, count: 12)))
    }
}

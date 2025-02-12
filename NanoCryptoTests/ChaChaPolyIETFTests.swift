//
//  ChaChaPolyIETFTests.swift
//  NanoCryptoTests
//
//  Created by Richard Henry on 3/21/24.
//

import CryptoKit
import XCTest

@testable import NanoCrypto

final class ChaChaPolyIETFTests: XCTestCase {
    func testSealedBox() throws {
        let message = Data(randomBytes: 10_123)
        let key = SymmetricKey(size: .bits256)

        let sealedBox = try ChaChaPolyIETF.seal(message, using: key)

        XCTAssertEqual(sealedBox.ciphertext.count, message.count)
        XCTAssertEqual(sealedBox.tag.count, ChaChaPolyIETF.tagBytes)
        XCTAssertEqual(sealedBox.nonce.data.count, ChaChaPolyIETF.nonceBytes)

        XCTAssertEqual(
            sealedBox.combined.count,
            message.count + ChaChaPolyIETF.tagBytes + ChaChaPolyIETF.nonceBytes
        )
    }

    func testSealedBoxEmpty() throws {
        let message = Data()
        let key = SymmetricKey(size: .bits256)

        let sealedBox = try ChaChaPolyIETF.seal(message, using: key)

        XCTAssertEqual(sealedBox.ciphertext.count, 0)
        XCTAssertEqual(sealedBox.tag.count, ChaChaPolyIETF.tagBytes)
        XCTAssertEqual(sealedBox.nonce.data.count, ChaChaPolyIETF.nonceBytes)

        XCTAssertEqual(
            sealedBox.combined.count,
            ChaChaPolyIETF.tagBytes + ChaChaPolyIETF.nonceBytes
        )
    }

    func testEncryptDecrypt() throws {
        let message = Data(randomBytes: 10_123)
        let key = SymmetricKey(size: .bits256)

        let sealedBox = try ChaChaPolyIETF.seal(message, using: key)
        let decrypted = try ChaChaPolyIETF.open(sealedBox, using: key)

        XCTAssertEqual(message, decrypted)

        XCTAssertThrowsError(
            try ChaChaPolyIETF.open(sealedBox, using: SymmetricKey(size: .bits256))
        )
    }

    func testDecryptIntoSecureMemory() throws {
        let message = Data(randomBytes: 10_123)
        let key = SymmetricKey(size: .bits256)

        let sealedBox = try ChaChaPolyIETF.seal(message, using: key)
        // We are not currently validating that this is using SecureBytes in this unit test, but this can be verified by setting a breakpoint and inspecting the deallocator for the data storage. We should add a mock for secure data that allows us to verify this programatically.
        let decrypted = try ChaChaPolyIETF.open(sealedBox, using: key, intoSecureMemory: true)

        XCTAssertEqual(message, decrypted)
    }

    func testEncryptDecryptWrongKey() throws {
        let sealedBox = try ChaChaPolyIETF.seal(
            Data(randomBytes: 10_123),
            using: SymmetricKey(size: .bits256)
        )

        XCTAssertThrowsError(
            try ChaChaPolyIETF.open(sealedBox, using: SymmetricKey(size: .bits256))
        )
    }

    func testEncryptDecryptEmptyMessage() throws {
        let key = SymmetricKey(size: .bits256)

        let sealedBox = try ChaChaPolyIETF.seal(Data(), using: key)
        let decrypted = try ChaChaPolyIETF.open(sealedBox, using: key)

        XCTAssertEqual(decrypted.count, 0)
    }

    func testAuthenticatedData() throws {
        let message = Data(randomBytes: 10_123)
        let key = SymmetricKey(size: .bits256)

        let sealedBox = try ChaChaPolyIETF.seal(
            message,
            using: key,
            authenticating: Data("hello 123".utf8)
        )
        let decrypted = try ChaChaPolyIETF.open(
            sealedBox,
            using: key,
            authenticating: Data("hello 123".utf8)
        )

        XCTAssertEqual(message, decrypted)

        XCTAssertThrowsError(
            try ChaChaPolyIETF.open(sealedBox, using: key, authenticating: Data("hello 456".utf8))
        )

        XCTAssertThrowsError(try ChaChaPolyIETF.open(sealedBox, using: key))
    }

    func testNonceSanityCheck() throws {
        XCTAssertNotEqual(ChaChaPolyIETF.Nonce().data, ChaChaPolyIETF.Nonce().data)
        XCTAssertEqual(ChaChaPolyIETF.Nonce().data.count, 12)
    }

    func testWrongKeySize() throws {
        XCTAssertThrowsError(
            try ChaChaPolyIETF.seal(Data(randomBytes: 100), using: SymmetricKey(size: .bits192))
        )
    }

    func testWrongNonceSize() throws {
        XCTAssertThrowsError(try ChaChaPolyIETF.Nonce(data: Data(repeating: 0, count: 8)))
        XCTAssertThrowsError(try ChaChaPolyIETF.Nonce(data: Data(repeating: 0, count: 24)))
    }

    func testWrongCombinedDataSize() throws {
        XCTAssertThrowsError(try ChaChaPolyIETF.SealedBox(combined: Data(repeating: 0, count: 12)))
    }
}

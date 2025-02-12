//
//  LabyrinthPQHPKETests.swift
//  NanoCryptoTests
//
//  Created by Richard Henry on 3/21/24.
//

import CryptoKit
import XCTest

@testable import NanoCrypto

final class LabyrinthPQHPKETests: XCTestCase {
    func testSealedBox() throws {
        let recipientKey = Curve25519.KeyAgreement.PrivateKey()
        let recipientKeyKyber = try Kyber1024.pair()
        let senderKey = Curve25519.KeyAgreement.PrivateKey()
        let preSharedKey = SymmetricKey(size: .bits256)

        let sealedBox = try LabyrinthPQHPKE.seal(
            recipientKey: recipientKey.publicKey,
            recipientKeyKyber: recipientKeyKyber.publicKey,
            senderKey: senderKey,
            preSharedKey: preSharedKey,
            message: Data("some message".utf8),
            authenticating: Data("some aad".utf8)
        )

        XCTAssertEqual(sealedBox.combined.first, "L".first!.asciiValue)
        XCTAssertEqual(try sealedBox.ephemeralKey.rawRepresentation.count, 32)
        XCTAssertEqual(
            try sealedBox.kyberCiphertext.rawRepresentation.count,
            Kyber1024.Ciphertext.sizeBytes
        )
        let innerBox = try sealedBox.innerBox

        XCTAssertEqual(
            sealedBox.combined.count,
            1 + 32 + Kyber1024.Ciphertext.sizeBytes + innerBox.combined.count
        )
    }

    func testSealedBoxEmpty() throws {
        let recipientKey = Curve25519.KeyAgreement.PrivateKey()
        let recipientKeyKyber = try Kyber1024.pair()
        let senderKey = Curve25519.KeyAgreement.PrivateKey()
        let preSharedKey = SymmetricKey(size: .bits256)

        let sealedBox = try LabyrinthPQHPKE.seal(
            recipientKey: recipientKey.publicKey,
            recipientKeyKyber: recipientKeyKyber.publicKey,
            senderKey: senderKey,
            preSharedKey: preSharedKey,
            message: Data(),
            authenticating: Data("some aad".utf8)
        )

        XCTAssertEqual(try sealedBox.ephemeralKey.rawRepresentation.count, 32)
        XCTAssertEqual(
            try sealedBox.kyberCiphertext.rawRepresentation.count,
            Kyber1024.Ciphertext.sizeBytes
        )
        let innerBox = try sealedBox.innerBox

        XCTAssertEqual(
            sealedBox.combined.count,
            1 + 32 + Kyber1024.Ciphertext.sizeBytes + innerBox.combined.count
        )
    }

    func testEncryptDecrypt() throws {
        let recipientKey = Curve25519.KeyAgreement.PrivateKey()
        let recipientKeyKyber = try Kyber1024.pair()
        let senderKey = Curve25519.KeyAgreement.PrivateKey()
        let preSharedKey = SymmetricKey(size: .bits256)

        let sealedBox = try LabyrinthPQHPKE.seal(
            recipientKey: recipientKey.publicKey,
            recipientKeyKyber: recipientKeyKyber.publicKey,
            senderKey: senderKey,
            preSharedKey: preSharedKey,
            message: Data("some message".utf8),
            authenticating: Data("some aad".utf8)
        )

        let decrypted = try LabyrinthPQHPKE.open(
            sealedBox,
            recipientKey: recipientKey,
            recipientKeyKyber: recipientKeyKyber.privateKey,
            senderKey: senderKey.publicKey,
            preSharedKey: preSharedKey,
            authenticating: Data("some aad".utf8)
        )

        XCTAssertEqual(Data("some message".utf8), decrypted)
    }

    func testEncryptDecryptIncorrectPSK() throws {
        let recipientKey = Curve25519.KeyAgreement.PrivateKey()
        let recipientKeyKyber = try Kyber1024.pair()
        let senderKey = Curve25519.KeyAgreement.PrivateKey()
        let preSharedKey = SymmetricKey(size: .bits256)

        let sealedBox = try LabyrinthPQHPKE.seal(
            recipientKey: recipientKey.publicKey,
            recipientKeyKyber: recipientKeyKyber.publicKey,
            senderKey: senderKey,
            preSharedKey: preSharedKey,
            message: Data("some message".utf8),
            authenticating: Data("some aad".utf8)
        )

        XCTAssertThrowsError(
            try LabyrinthPQHPKE.open(
                sealedBox,
                recipientKey: recipientKey,
                recipientKeyKyber: recipientKeyKyber.privateKey,
                senderKey: senderKey.publicKey,
                preSharedKey: SymmetricKey(size: .bits256),
                authenticating: Data("some aad".utf8)
            )
        )
    }

    func testEncryptIncorrectPSKSize() throws {
        let recipientKey = Curve25519.KeyAgreement.PrivateKey()
        let recipientKeyKyber = try Kyber1024.pair()
        let senderKey = Curve25519.KeyAgreement.PrivateKey()
        let preSharedKey = SymmetricKey(size: .bits192)

        XCTAssertThrowsError(
            try LabyrinthPQHPKE.seal(
                recipientKey: recipientKey.publicKey,
                recipientKeyKyber: recipientKeyKyber.publicKey,
                senderKey: senderKey,
                preSharedKey: preSharedKey,
                message: Data("some message".utf8),
                authenticating: Data("some aad".utf8)
            )
        )
    }

    func testEncryptDecryptBadAuthenticatedData() throws {
        let recipientKey = Curve25519.KeyAgreement.PrivateKey()
        let recipientKeyKyber = try Kyber1024.pair()
        let senderKey = Curve25519.KeyAgreement.PrivateKey()
        let preSharedKey = SymmetricKey(size: .bits256)

        let sealedBox = try LabyrinthPQHPKE.seal(
            recipientKey: recipientKey.publicKey,
            recipientKeyKyber: recipientKeyKyber.publicKey,
            senderKey: senderKey,
            preSharedKey: preSharedKey,
            message: Data("some message".utf8),
            authenticating: Data("some aad".utf8)
        )

        XCTAssertThrowsError(
            try LabyrinthPQHPKE.open(
                sealedBox,
                recipientKey: recipientKey,
                recipientKeyKyber: recipientKeyKyber.privateKey,
                senderKey: senderKey.publicKey,
                preSharedKey: preSharedKey,
                authenticating: Data("other aad".utf8)
            )
        )
    }

    func testEncryptDecryptBadRecipientKey() throws {
        let recipientKey = Curve25519.KeyAgreement.PrivateKey()
        let recipientKeyKyber = try Kyber1024.pair()
        let senderKey = Curve25519.KeyAgreement.PrivateKey()
        let preSharedKey = SymmetricKey(size: .bits256)

        let sealedBox = try LabyrinthPQHPKE.seal(
            recipientKey: recipientKey.publicKey,
            recipientKeyKyber: recipientKeyKyber.publicKey,
            senderKey: senderKey,
            preSharedKey: preSharedKey,
            message: Data("some message".utf8),
            authenticating: Data("some aad".utf8)
        )

        XCTAssertThrowsError(
            try LabyrinthPQHPKE.open(
                sealedBox,
                recipientKey: Curve25519.KeyAgreement.PrivateKey(),
                recipientKeyKyber: recipientKeyKyber.privateKey,
                senderKey: senderKey.publicKey,
                preSharedKey: preSharedKey,
                authenticating: Data("some aad".utf8)
            )
        )
    }

    func testEncryptDecryptBadRecipientKeyKyber() throws {
        let recipientKey = Curve25519.KeyAgreement.PrivateKey()
        let recipientKeyKyber = try Kyber1024.pair()
        let senderKey = Curve25519.KeyAgreement.PrivateKey()
        let preSharedKey = SymmetricKey(size: .bits256)

        let sealedBox = try LabyrinthPQHPKE.seal(
            recipientKey: recipientKey.publicKey,
            recipientKeyKyber: recipientKeyKyber.publicKey,
            senderKey: senderKey,
            preSharedKey: preSharedKey,
            message: Data("some message".utf8),
            authenticating: Data("some aad".utf8)
        )

        XCTAssertThrowsError(
            try LabyrinthPQHPKE.open(
                sealedBox,
                recipientKey: recipientKey,
                recipientKeyKyber: try Kyber1024.pair().privateKey,
                senderKey: senderKey.publicKey,
                preSharedKey: preSharedKey,
                authenticating: Data("some aad".utf8)
            )
        )
    }

    func testEncryptDecryptBadSenderKey() throws {
        let recipientKey = Curve25519.KeyAgreement.PrivateKey()
        let recipientKeyKyber = try Kyber1024.pair()
        let senderKey = Curve25519.KeyAgreement.PrivateKey()
        let preSharedKey = SymmetricKey(size: .bits256)

        let sealedBox = try LabyrinthPQHPKE.seal(
            recipientKey: recipientKey.publicKey,
            recipientKeyKyber: recipientKeyKyber.publicKey,
            senderKey: senderKey,
            preSharedKey: preSharedKey,
            message: Data("some message".utf8),
            authenticating: Data("some aad".utf8)
        )

        XCTAssertThrowsError(
            try LabyrinthPQHPKE.open(
                sealedBox,
                recipientKey: recipientKey,
                recipientKeyKyber: recipientKeyKyber.privateKey,
                senderKey: Curve25519.KeyAgreement.PrivateKey().publicKey,
                preSharedKey: preSharedKey,
                authenticating: Data("some aad".utf8)
            )
        )
    }
}

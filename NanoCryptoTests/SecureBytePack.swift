//
//  SecureBytePack.swift
//  NanoCryptoTests
//
//  Created by Richard Henry on 3/19/24.
//

import CryptoKit
import XCTest

@testable import NanoCrypto

final class SecureBytePackTests: XCTestCase {
    func testPackUnpack() throws {
        let a0 = SymmetricKey(size: .bits256)
        let b0 = SymmetricKey(size: .bits256)

        let p0 = SecureBytePack([a0, b0])
        let packed = try p0.pack()

        XCTAssertEqual(packed.count, 64)

        let p1 = try SecureBytePack(
            from: packed,
            layout: [
                .item(SymmetricKey.self, sizeBytes: 32),
                .item(SymmetricKey.self, sizeBytes: 32),
            ]
        )

        XCTAssertEqual(a0, try p1.item(at: 0))
        XCTAssertEqual(b0, try p1.item(at: 1))
    }

    func testPackUnpackVariable() throws {
        let a0 = SymmetricKey(size: .bits128)
        let a1 = Curve25519.KeyAgreement.PrivateKey()
        let a2 = SymmetricKey(size: .bits192)
        let a3 = try Kyber1024.pair().privateKey

        let p0 = SecureBytePack([a0, a1, a2, a3])
        let packed = try p0.pack()

        XCTAssertEqual(packed.count, 16 + 32 + 24 + Kyber1024.PrivateKey.sizeBytes)

        let p1 = try SecureBytePack(
            from: packed,
            layout: [
                .item(SymmetricKey.self, sizeBytes: 16),
                .item(Curve25519.KeyAgreement.PrivateKey.self),
                .item(SymmetricKey.self, sizeBytes: 24),
                .item(Kyber1024.PrivateKey.self),
            ]
        )

        XCTAssertEqual(a0, try p1.item(at: 0))
        XCTAssertEqual(a1, try p1.item(at: 1))
        XCTAssertEqual(a2, try p1.item(at: 2))
        XCTAssertEqual(a3, try p1.item(at: 3))
    }

    func testUnpackLayoutError() throws {
        let a0 = SymmetricKey(size: .bits128)
        let a1 = Curve25519.KeyAgreement.PrivateKey()
        let a2 = SymmetricKey(size: .bits192)
        let a3 = try Kyber1024.pair().privateKey

        let p0 = SecureBytePack([a0, a1, a2, a3])
        let packed = try p0.pack()

        XCTAssertEqual(packed.count, 16 + 32 + 24 + Kyber1024.PrivateKey.sizeBytes)

        XCTAssertThrowsError(
            try SecureBytePack(
                from: packed,
                layout: [
                    .item(SymmetricKey.self, sizeBytes: 16),
                    .item(Curve25519.KeyAgreement.PrivateKey.self),
                    .item(SymmetricKey.self, sizeBytes: 24),
                ]
            )
        )

        XCTAssertThrowsError(
            try SecureBytePack(
                from: packed,
                layout: [
                    .item(SymmetricKey.self, sizeBytes: 16),
                    .item(Curve25519.KeyAgreement.PrivateKey.self),
                    .item(SymmetricKey.self, sizeBytes: 24),
                    .item(Kyber1024.PrivateKey.self),
                    .item(SymmetricKey.self, sizeBytes: 32),
                ]
            )
        )
    }

    func testUnpackItemError() throws {
        let a0 = SymmetricKey(size: .bits256)
        let p0 = SecureBytePack([a0])
        let packed = try p0.pack()

        XCTAssertEqual(packed.count, 32)

        let p1 = try SecureBytePack(
            from: packed,
            layout: [
                .item(SymmetricKey.self, sizeBytes: 32)
            ]
        )

        XCTAssertThrowsError(try p1.item(at: 0) as Curve25519.KeyAgreement.PrivateKey)

        XCTAssertThrowsError(try p1.item(at: 1) as SymmetricKey)
    }
}

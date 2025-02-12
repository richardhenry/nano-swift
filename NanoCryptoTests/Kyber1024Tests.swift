//
//  Kyber1024Tests.swift
//  Kyber1024Tests
//
//  Created by Richard Henry on 1/8/24.
//

import XCTest

@testable import NanoCrypto

final class Kyber1024Tests: XCTestCase {
    func testSwiftInterface() throws {
        let k0 = try Kyber1024.pair()
        let (sk0, pk0) = (k0.privateKey, k0.publicKey)

        let (ss0_a, ct0) = try pk0.encrypt()

        let ss0_b = try sk0.decrypt(ciphertext: ct0)

        XCTAssertEqual(ss0_a.rawRepresentation, ss0_b.rawRepresentation)

        let k1 = try Kyber1024.pair()
        let (sk1, pk1) = (k1.privateKey, k1.publicKey)

        // sanity check
        XCTAssertNotEqual(sk1.rawRepresentation, sk0.rawRepresentation)
        XCTAssertNotEqual(pk1.rawRepresentation, pk0.rawRepresentation)

        let (ss1_a, ct1) = try pk1.encrypt()

        let ss1_b = try sk1.decrypt(ciphertext: ct1)

        XCTAssertEqual(ss1_a.rawRepresentation, ss1_b.rawRepresentation)

        // test data initializer
        let pk2 = try Kyber1024.PrivateKey(rawRepresentation: pk1.rawRepresentation)
        XCTAssertEqual(pk2.rawRepresentation, pk1.rawRepresentation)

        // sanity check
        let ss2 = try sk1.decrypt(ciphertext: ct0)
        XCTAssertNotEqual(ss2.rawRepresentation, ss0_a.rawRepresentation)
        XCTAssertNotEqual(ss2.rawRepresentation, ss0_b.rawRepresentation)
    }

    func testKeyPairPerf() throws {
        measure {
            _ = try! Kyber1024.pair()
        }
    }

    func testEncryptPerf() throws {
        let pk = try Kyber1024.pair().publicKey

        measure {
            _ = try! pk.encrypt()
        }
    }

    func testDecryptPerf() throws {
        let k = try Kyber1024.pair()
        let (sk, pk) = (k.privateKey, k.publicKey)
        let (_, ct) = try pk.encrypt()

        measure {
            _ = try! sk.decrypt(ciphertext: ct)
        }
    }
}

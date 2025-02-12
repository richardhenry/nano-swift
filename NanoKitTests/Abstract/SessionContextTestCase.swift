//
//  SessionContextTestCase.swift
//  NanoKitTests
//
//  Created by Richard Henry on 3/29/24.
//

import CryptoKit
import NanoCore
import NanoCrypto
import XCTest

@testable import NanoKit

class SessionContextTestCase: XCTestCase {
    var userId: UserID!
    var recoveryKey: SymmetricKey!
    var signingKey: Curve25519.Signing.PrivateKey!
    var now: Timestamp!
    var dataStore: DataStore!
    var keychainStorage: KeychainStorage!

    override func setUp() async throws {
        try await super.setUp()
        try await reset()
    }

    public func reset() async throws {
        userId = UserID()
        recoveryKey = SymmetricKey(size: .bits256)
        signingKey = Curve25519.Signing.PrivateKey()
        now = .now()

        dataStore = DataStore.ephemeral()
        keychainStorage = KeychainStorage.ephemeral()

        let session = SessionModel(
            userId: userId,
            sessionId: 3,
            token: Data(randomBytes: 32).urlSafeBase64EncodedString(),
            timestamp: now
        )

        let userKey = UserKeyModel(
            id: userId,
            signing: signingKey.publicKey,
            timestamp: now
        )

        try keychainStorage.save(
            recoveryKey,
            to: .recoveryKey(userId)
        )

        try keychainStorage.save(
            signingKey,
            to: .userSigningKey(userId)
        )

        try await dataStore.write { db in
            try session.replace(db)
            try userKey.insert(db)
        }
    }
}

final class SessionContextTestCaseTests: SessionContextTestCase {
    func testSessionFixtures() async {
        let (s0, u0) = try! await dataStore.read { [self] db in
            let session = try! SessionModel.fetchExpect(db)
            XCTAssertEqual(session.userId, userId)
            XCTAssertEqual(session.sessionId, 3)
            XCTAssertFalse(session.token.isEmpty)
            XCTAssertEqual(session.timestamp, now)

            let userKey = try! UserKeyModel.fetchExpect(db)
            XCTAssertEqual(userKey.id, userId)
            XCTAssertEqual(userKey.timestamp, now)
            XCTAssertEqual(userKey.signing, signingKey.publicKey)

            return (session, userKey)
        }

        let k0: Curve25519.Signing.PrivateKey = try! keychainStorage.get(
            .userSigningKey(userId)
        )

        try! await reset()

        let (s1, u1) = try! await dataStore.read { [self] db in
            let session = try! SessionModel.fetchExpect(db)
            XCTAssertEqual(session.userId, userId)
            XCTAssertEqual(session.sessionId, 3)
            XCTAssertFalse(session.token.isEmpty)
            XCTAssertEqual(session.timestamp, now)

            let userKey = try! UserKeyModel.fetchExpect(db)
            XCTAssertEqual(userKey.id, userId)
            XCTAssertEqual(userKey.timestamp, now)
            XCTAssertEqual(userKey.signing, signingKey.publicKey)

            return (session, userKey)
        }

        let k1: Curve25519.Signing.PrivateKey = try! keychainStorage.get(
            .userSigningKey(userId)
        )

        XCTAssertNotEqual(s0, s1)
        XCTAssertNotEqual(u0, u1)
        XCTAssertNotEqual(k0, k1)
    }

    func testMethodIsolation_0() {
        try! dataStore.read { db in
            XCTAssertNil(try UserModel.fetchOne(db))
        }

        try! dataStore.write { db in
            try UserModel(id: userId, name: "Bob").save(db)
        }
    }

    func testMethodIsolation_1() {
        try! dataStore.read { db in
            XCTAssertNil(try UserModel.fetchOne(db))
        }

        try! dataStore.write { db in
            try UserModel(id: userId, name: "Bob").save(db)
        }
    }
}

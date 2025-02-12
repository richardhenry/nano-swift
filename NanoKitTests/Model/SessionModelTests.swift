//
//  SessionModelTests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 3/20/24.
//

import CryptoKit
import XCTest

@testable import NanoKit

final class SessionModelTests: XCTestCase {
    func testModel() throws {
        let u1 = UserID()
        let u2 = UserID()
        let t1 = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }.base64EncodedString()
        let t2 = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }.base64EncodedString()

        let dataStore = DataStore.ephemeral()

        try dataStore.write { db in
            _ = try SessionModel(
                userId: u1,
                sessionId: 0,
                token: t1,
                timestamp: 1_704_696_536_048
            )
            .replace(db)
        }

        let s0 = try dataStore.read { db in
            try SessionModel.fetchExpect(db)
        }

        XCTAssertEqual(s0.userId, u1)
        XCTAssertEqual(s0.sessionId, 0)
        XCTAssertEqual(s0.token, t1)
        XCTAssertEqual(s0.timestamp, 1_704_696_536_048)

        try dataStore.write { db in
            _ = try SessionModel(
                userId: u2,
                sessionId: 1,
                token: t2,
                timestamp: 1_704_696_536_050
            )
            .replace(db)
        }

        let s1 = try dataStore.read { db in
            try SessionModel.fetchExpect(db)
        }
        XCTAssertEqual(s1.userId, u2)
        XCTAssertEqual(s1.sessionId, 1)
        XCTAssertEqual(s1.token, t2)
        XCTAssertEqual(s1.timestamp, 1_704_696_536_050)

        let count = try dataStore.read { db in
            try SessionModel.fetchCount(db)
        }
        XCTAssertEqual(count, 1)
    }
}

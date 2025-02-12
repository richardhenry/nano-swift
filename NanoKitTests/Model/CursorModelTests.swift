//
//  CursorModelTests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 5/5/24.
//

import XCTest

@testable import NanoKit

final class CursorModelTests: XCTestCase {
    func testSingleEmptyPath() throws {
        let dataStore = DataStore.ephemeral()

        let key = FetchKey(fetchType: .member)

        let a = CursorModel(
            key: key,
            start: FetchIndex(
                timestamp: 1000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001100")!
            ),
            end: nil
        )

        try dataStore.write { db in
            try a.save(db)
        }

        let b = try dataStore.read { db in
            try CursorModel.fetchOne(db, key: key)
        }

        XCTAssertEqual(a, b)
    }

    func testSinglePartPath() throws {
        let dataStore = DataStore.ephemeral()

        let key = FetchKey(fetchType: .member, path: GroupID())

        let a = CursorModel(
            key: key,
            start: FetchIndex(
                timestamp: 1000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001100")!
            ),
            end: nil
        )

        try dataStore.write { db in
            try a.save(db)
        }

        let b = try dataStore.read { db in
            try CursorModel.fetchOne(db, key: key)
        }

        XCTAssertEqual(a, b)
    }

    func testMultiPartPath() throws {
        let dataStore = DataStore.ephemeral()

        let key = FetchKey(fetchType: .member, path: GroupID(), ThreadID())

        let a = CursorModel(
            key: key,
            start: FetchIndex(
                timestamp: 1000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001100")!
            ),
            end: nil
        )

        try dataStore.write { db in
            try a.save(db)
        }

        let b = try dataStore.read { db in
            try CursorModel.fetchOne(db, key: key)
        }

        XCTAssertEqual(a, b)
    }

    func testExtendClosed() throws {
        let dataStore = DataStore.ephemeral()

        let key = FetchKey(fetchType: .message, path: GroupID(), ThreadID())

        let a = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 6000, id: MessageID()),
            end: FetchIndex(timestamp: 5000, id: MessageID())
        )

        try dataStore.write { db in
            try a.save(db)
        }

        let b = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 3000, id: MessageID()),
            end: FetchIndex(timestamp: 1000, id: MessageID())
        )

        try dataStore.write { db in
            try b.save(db)
        }

        var c = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 5001, id: MessageID()),
            end: FetchIndex(timestamp: 2999, id: MessageID())
        )

        try dataStore.read { db in
            try c.extend(db)
        }

        XCTAssertEqual(c.start, a.start)
        XCTAssertEqual(c.end, b.end)
    }

    func testExtendOpen() throws {
        let dataStore = DataStore.ephemeral()

        let key = FetchKey(fetchType: .message, path: GroupID(), ThreadID())

        let a = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 6000, id: MessageID()),
            end: FetchIndex(timestamp: 5000, id: MessageID())
        )

        try dataStore.write { db in
            try a.save(db)
        }

        let b = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 3000, id: MessageID()),
            end: nil
        )

        try dataStore.write { db in
            try b.save(db)
        }

        var c = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 5001, id: MessageID()),
            end: FetchIndex(timestamp: 2999, id: MessageID())
        )

        try dataStore.read { db in
            try c.extend(db)
        }

        XCTAssertEqual(c.start, a.start)
        XCTAssertEqual(c.end, b.end)
    }

    func testExtendEdgeOverlap() throws {
        let dataStore = DataStore.ephemeral()

        let key = FetchKey(fetchType: .message, path: GroupID(), ThreadID())

        let a = CursorModel(
            key: key,
            start: FetchIndex(
                timestamp: 6000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000000000")!
            ),
            end: FetchIndex(
                timestamp: 5000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001100")!
            )
        )

        try dataStore.write { db in
            try a.save(db)
        }

        let b = CursorModel(
            key: key,
            start: FetchIndex(
                timestamp: 3000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000000011")!
            ),
            end: nil
        )

        try dataStore.write { db in
            try b.save(db)
        }

        var c = CursorModel(
            key: key,
            start: FetchIndex(
                timestamp: 5000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001100")!
            ),
            end: FetchIndex(
                timestamp: 3000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000000011")!
            )
        )

        try dataStore.read { db in
            try c.extend(db)
        }

        XCTAssertEqual(c.start, a.start)
        XCTAssertEqual(c.end, b.end)
    }

    func testExtendNotOverlapping() throws {
        let dataStore = DataStore.ephemeral()

        let key = FetchKey(fetchType: .message, path: GroupID(), ThreadID())

        let a = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 6000, id: MessageID()),
            end: FetchIndex(timestamp: 5000, id: MessageID())
        )

        try dataStore.write { db in
            try a.save(db)
        }

        let b = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 2998, id: MessageID()),
            end: FetchIndex(timestamp: 1000, id: MessageID())
        )

        try dataStore.write { db in
            try b.save(db)
        }

        let c1 = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 5001, id: MessageID()),
            end: FetchIndex(timestamp: 2999, id: MessageID())
        )

        var c2 = c1

        try dataStore.read { db in
            try c2.extend(db)
        }

        XCTAssertEqual(c2.start, a.start)
        XCTAssertEqual(c2.end, c1.end)
    }

    func testDeleteRedundantClosed() throws {
        let dataStore = DataStore.ephemeral()

        let key = FetchKey(fetchType: .message, path: GroupID(), ThreadID())

        let a = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 6000, id: MessageID()),
            end: FetchIndex(timestamp: 5000, id: MessageID())
        )

        try dataStore.write { db in
            try a.save(db)
        }

        let b = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 3000, id: MessageID()),
            end: FetchIndex(timestamp: 1000, id: MessageID())
        )

        try dataStore.write { db in
            try b.save(db)
        }

        let c = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 6100, id: MessageID()),
            end: FetchIndex(timestamp: 900, id: MessageID())
        )

        let remaining = try dataStore.write { db in
            try CursorModel.deleteRedundant(db, withCursor: c)
            return try CursorModel.fetchAll(db)
        }

        XCTAssertEqual(remaining.count, 0)
    }

    func testDeleteRedundantOpen() throws {
        let dataStore = DataStore.ephemeral()

        let key = FetchKey(fetchType: .message, path: GroupID(), ThreadID())

        let a = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 6000, id: MessageID()),
            end: FetchIndex(timestamp: 5000, id: MessageID())
        )

        try dataStore.write { db in
            try a.save(db)
        }

        let b = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 3000, id: MessageID()),
            end: FetchIndex(timestamp: 1000, id: MessageID())
        )

        try dataStore.write { db in
            try b.save(db)
        }

        let c = CursorModel(
            key: key,
            start: FetchIndex(timestamp: 6100, id: MessageID()),
            end: nil
        )

        let remaining = try dataStore.write { db in
            try CursorModel.deleteRedundant(db, withCursor: c)
            return try CursorModel.fetchAll(db)
        }

        XCTAssertEqual(remaining.count, 0)
    }

    func testContaining() throws {
        let dataStore = DataStore.ephemeral()

        let key = FetchKey(fetchType: .message, path: GroupID(), ThreadID())

        let cursor = CursorModel(
            key: key,
            start: FetchIndex(
                timestamp: 6000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000000011")!
            ),
            end: FetchIndex(
                timestamp: 5000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001100")!
            )
        )

        try dataStore.write { db in
            try cursor.save(db)
        }

        func assertContains(_ index: FetchIndex) throws {
            let result = try dataStore.read { db in
                try CursorModel.fetchContaining(db, key: key, index: index)
            }
            XCTAssertEqual(result, cursor)
        }

        func assertNotContains(_ index: FetchIndex) throws {
            let result = try dataStore.read { db in
                try CursorModel.fetchContaining(db, key: key, index: index)
            }
            XCTAssertNil(result)
        }

        try assertNotContains(
            FetchIndex(
                timestamp: 6002,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001111")!
            )
        )

        try assertNotContains(
            FetchIndex(
                timestamp: 6001,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001111")!
            )
        )

        try assertNotContains(
            FetchIndex(
                timestamp: 6000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000000000")!
            )
        )

        try assertContains(
            FetchIndex(
                timestamp: 6000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000000011")!
            )
        )

        try assertContains(
            FetchIndex(
                timestamp: 6000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001111")!
            )
        )

        try assertContains(
            FetchIndex(
                timestamp: 5500,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001111")!
            )
        )

        try assertContains(
            FetchIndex(
                timestamp: 5000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000000000")!
            )
        )

        try assertContains(
            FetchIndex(
                timestamp: 5000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000000011")!
            )
        )

        try assertContains(
            FetchIndex(
                timestamp: 5000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001100")!
            )
        )

        try assertNotContains(
            FetchIndex(
                timestamp: 5000,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001111")!
            )
        )

        try assertNotContains(
            FetchIndex(
                timestamp: 4999,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001111")!
            )
        )

        try assertNotContains(
            FetchIndex(
                timestamp: 4500,
                id: MessageID(uuidString: "00000000-0000-0000-0000-000000001111")!
            )
        )
    }
}

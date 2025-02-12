//
//  EpochDirtyModelTests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 3/28/24.
//

import XCTest

@testable import NanoKit

final class EpochDirtyModelTests: XCTestCase {
    func testModel() throws {
        let dataStore = DataStore.ephemeral()

        let groupId = GroupID()

        let d0 = try dataStore.read { db in
            try EpochDirtyModel.fetchOne(db, id: groupId)
        }

        XCTAssertNil(d0)

        try dataStore.write { db in
            try EpochDirtyModel.set(db, id: groupId, lastEpochTimestamp: 10)
        }

        let d1 = try dataStore.read { db in
            try EpochDirtyModel.fetchOne(db, id: groupId)
        }

        XCTAssertEqual(d1?.lastEpochTimestamp, 10)
        XCTAssertNil(d1?.dirtyTimestamp)

        try dataStore.write { db in
            try EpochDirtyModel.set(db, id: groupId, dirtyTimestamp: 9)
        }

        let d2 = try dataStore.read { db in
            try EpochDirtyModel.fetchOne(db, id: groupId)
        }

        XCTAssertEqual(d2?.lastEpochTimestamp, 10)
        XCTAssertEqual(d2?.dirtyTimestamp, 9)

        let dirty1 = try dataStore.read { db in
            try EpochDirtyModel.fetchDirty(db, now: 11)
        }

        XCTAssertTrue(dirty1.isEmpty)

        let dirty1b = try dataStore.read { db in
            try EpochDirtyModel.fetchDirty(
                db,
                now: d2!.lastEpochTimestamp! + EpochDirtyModel.maximumLifetime + 1
            )
        }

        XCTAssertEqual(dirty1b.count, 1)
        XCTAssertEqual(dirty1b[0].id, groupId)
        XCTAssertEqual(dirty1b[0].lastEpochTimestamp, 10)
        XCTAssertEqual(dirty1b[0].dirtyTimestamp, 9)

        try dataStore.write { db in
            try EpochDirtyModel.set(db, id: groupId, dirtyTimestamp: 10)
        }

        let d3 = try dataStore.read { db in
            try EpochDirtyModel.fetchOne(db, id: groupId)
        }

        XCTAssertEqual(d3?.lastEpochTimestamp, 10)
        XCTAssertEqual(d3?.dirtyTimestamp, 10)

        let dirty2 = try dataStore.read { db in
            try EpochDirtyModel.fetchDirty(db, now: 11)
        }

        XCTAssertTrue(dirty2.isEmpty)

        try dataStore.write { db in
            try EpochDirtyModel.set(db, id: groupId, dirtyTimestamp: 11)
        }

        let d4 = try dataStore.read { db in
            try EpochDirtyModel.fetchOne(db, id: groupId)
        }

        XCTAssertEqual(d4?.lastEpochTimestamp, 10)
        XCTAssertEqual(d4?.dirtyTimestamp, 11)

        let dirty3 = try dataStore.read { db in
            try EpochDirtyModel.fetchDirty(db, now: 11)
        }

        XCTAssertEqual(dirty3.count, 1)
        XCTAssertEqual(dirty3[0].id, groupId)
        XCTAssertEqual(dirty3[0].lastEpochTimestamp, 10)
        XCTAssertEqual(dirty3[0].dirtyTimestamp, 11)
    }

    func testEpochTimestampIncrement() throws {
        let dataStore = DataStore.ephemeral()

        let groupId = GroupID()

        try dataStore.write { db in
            try EpochDirtyModel.set(db, id: groupId, lastEpochTimestamp: 1)
        }

        let d0 = try dataStore.read { db in
            try EpochDirtyModel.fetchOne(db, id: groupId)
        }

        XCTAssertEqual(d0?.lastEpochTimestamp, 1)

        try dataStore.write { db in
            try EpochDirtyModel.set(db, id: groupId, lastEpochTimestamp: 2)
        }

        let d1 = try dataStore.read { db in
            try EpochDirtyModel.fetchOne(db, id: groupId)
        }

        XCTAssertEqual(d1?.lastEpochTimestamp, 2)

        try dataStore.write { db in
            try EpochDirtyModel.set(db, id: groupId, lastEpochTimestamp: 1)
        }

        let d2 = try dataStore.read { db in
            try EpochDirtyModel.fetchOne(db, id: groupId)
        }

        XCTAssertEqual(d2?.lastEpochTimestamp, 2)
    }

    func testDirtyTimestampIncrement() throws {
        let dataStore = DataStore.ephemeral()

        let groupId = GroupID()

        try dataStore.write { db in
            try EpochDirtyModel.set(db, id: groupId, dirtyTimestamp: 1)
        }

        let d0 = try dataStore.read { db in
            try EpochDirtyModel.fetchOne(db, id: groupId)
        }

        XCTAssertEqual(d0?.dirtyTimestamp, 1)

        try dataStore.write { db in
            try EpochDirtyModel.set(db, id: groupId, dirtyTimestamp: 2)
        }

        let d1 = try dataStore.read { db in
            try EpochDirtyModel.fetchOne(db, id: groupId)
        }

        XCTAssertEqual(d1?.dirtyTimestamp, 2)

        try dataStore.write { db in
            try EpochDirtyModel.set(db, id: groupId, dirtyTimestamp: 1)
        }

        let d2 = try dataStore.read { db in
            try EpochDirtyModel.fetchOne(db, id: groupId)
        }

        XCTAssertEqual(d2?.dirtyTimestamp, 2)
    }
}

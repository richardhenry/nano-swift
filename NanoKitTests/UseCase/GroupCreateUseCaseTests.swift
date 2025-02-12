//
//  GroupCreateUseCaseTests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 3/29/24.
//

import CryptoKit
import NanoCrypto
import XCTest

@testable import NanoKit

final class GroupCreateUseCaseTests: SessionContextTestCase {
    func testUseCase() async {
        try! await GroupCreateUseCase(
            name: "My Group 123",
            image: nil,
            emoji: nil,
            dataStore: dataStore,
            keychainStorage: keychainStorage
        )
        .run()

        let (group, member, epoch, metadata, event) = try! await dataStore.read { db in
            let group = try! GroupModel.fetchExpect(db)
            let member = try! MemberModel.fetchExpect(db)
            let epoch = try! EpochModel.fetchExpect(db)
            let metadata = try! MetadataModel.fetchExpect(db)
            let event = try! PendingEvent.fetchExpect(db)
            return (group, member, epoch, metadata, event)
        }

        // Group
        XCTAssertEqual(group.name, "My Group 123")

        // Member
        XCTAssertEqual(member.groupId, group.id)
        XCTAssertEqual(member.userId, userId)

        // Epoch
        XCTAssertEqual(epoch.groupId, group.id)
        XCTAssertEqual(epoch.sequenceId, 0)

        // Metadata
        XCTAssertEqual(metadata.id, group.id)
        XCTAssertEqual(metadata.epochId, epoch.id)

        // Event
        XCTAssertEqual(event.eventType, .groupCreate)

        let payload = try! GroupCreatePayload.decode(from: event)
        XCTAssertEqual(payload.group.groupId, group.id)
        XCTAssertEqual(payload.member.groupId, member.groupId)
        XCTAssertEqual(payload.member.userId, member.userId)
        XCTAssertEqual(payload.epoch.groupId, epoch.groupId)
        XCTAssertEqual(payload.epoch.epochId, epoch.id)
        XCTAssertEqual(payload.metadata.groupId, group.id)

        // Epoch root key
        XCTAssertNotNil(
            try! keychainStorage.get(.epochRootKey(epoch.id)) as SymmetricKey
        )

        // Member keys
        XCTAssertNotNil(
            try! keychainStorage.get(.memberStoreKey(userId, group.id))
                as Curve25519.KeyAgreement.PrivateKey
        )
        XCTAssertNotNil(
            try! keychainStorage.get(.memberStoreKeyKyber(userId, group.id)) as Kyber1024.PrivateKey
        )
        XCTAssertNotNil(
            try! keychainStorage.get(.memberAuthKey(userId, group.id))
                as Curve25519.KeyAgreement.PrivateKey
        )
    }
}

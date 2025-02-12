//
//  InviteCreateUseCaseTests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 3/30/24.
//

import CryptoKit
import NanoCrypto
import XCTest

@testable import NanoKit

final class InviteCreateUseCaseTests: SessionContextTestCase {
    func testUseCase() async {
        let groupId = GroupID()

        try! await GroupCreateUseCase(
            groupId: groupId,
            name: "My Test Group",
            image: nil,
            emoji: nil,
            dataStore: dataStore,
            keychainStorage: keychainStorage
        )
        .run()

        try! await InviteCreateUseCase(
            groupId: groupId,
            lifetimeDuration: 123456,
            dataStore: dataStore,
            keychainStorage: keychainStorage
        )
        .run()

        let (invite, virtualMember, event) = try! await dataStore.read { db in
            let invite = try! InviteModel.fetchExpect(db)
            let virtualMember = try! VirtualMemberModel.fetchExpect(db)
            let event = try! PendingEvent.fetchExpectLatest(db)
            return (invite, virtualMember, event)
        }

        XCTAssertEqual(invite.groupId, groupId)

        XCTAssertEqual(virtualMember.ownerUserId, userId)
        XCTAssertEqual(virtualMember.groupId, groupId)

        let payload = try! InviteCreatePayload.decode(from: event)

        XCTAssertEqual(payload.invite.token.count, 32)
        XCTAssertEqual(payload.invite.groupId, groupId)
        XCTAssertEqual(payload.invite.ownerUserId, userId)
        XCTAssertEqual(payload.invite.lifetime, 123456)

        XCTAssertEqual(payload.virtualMember.groupId, groupId)
        XCTAssertEqual(payload.virtualMember.virtualId, payload.invite.virtualId)
        XCTAssertEqual(payload.virtualMember.ownerUserId, userId)

        XCTAssertNotNil(
            try! keychainStorage.get(.inviteSecretKey(invite.virtualId)) as SymmetricKey
        )
    }
}

//
//  InviteAcceptUseCaseTests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 3/30/24.
//

import CryptoKit
import NanoCrypto
import XCTest

@testable import NanoKit

final class InviteAcceptUseCaseTests: SessionContextTestCase {
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
            dataStore: dataStore,
            keychainStorage: keychainStorage
        )
        .run()

        let (initialEvents, initialUserKey) = try! await dataStore.read { db in
            (try! PendingEvent.fetchAll(db), try! UserKeyModel.fetchExpect(db))
        }

        XCTAssertEqual(initialEvents.count, 2)
        let groupCreatePayload = try! GroupCreatePayload.decode(from: initialEvents[0])
        let inviteCreatePayload = try! InviteCreatePayload.decode(from: initialEvents[1])

        let inviteBundle = InviteBundlePayload(
            invite: inviteCreatePayload.invite,
            group: GroupPayload(groupId: groupId, timestamp: now),
            metadata: groupCreatePayload.metadata,
            virtualMember: inviteCreatePayload.virtualMember,
            epochs: [EpochBundlePayload(epoch: groupCreatePayload.epoch, ciphertext: nil)]
        )

        let secretKey: SymmetricKey = try! keychainStorage.get(
            .inviteSecretKey(inviteCreatePayload.invite.virtualId)
        )

        try! await reset()

        try! await dataStore.write { db in
            XCTAssertEqual(try! GroupModel.fetchCount(db), 0)
            XCTAssertEqual(try! PendingEvent.fetchCount(db), 0)

            // Insert the key for the group creator
            try! initialUserKey.insert(db)
        }

        XCTAssertThrowsError(
            try keychainStorage.get(.epochRootKey(groupCreatePayload.epoch.epochId)) as SymmetricKey
        )

        try! await InviteAcceptUseCase(
            token: inviteBundle.invite.token,
            secretKey: secretKey,
            dataStore: dataStore,
            keychainStorage: keychainStorage
        )
        .handle(inviteBundle: inviteBundle)

        XCTAssertNotNil(
            try! keychainStorage.get(
                .epochRootKey(groupCreatePayload.epoch.epochId)
            )
                as SymmetricKey
        )

        let (group, epoch, member, acceptEvent, metadata) = try! await dataStore.read { db in
            XCTAssertEqual(try! EpochModel.fetchCount(db), 1)
            XCTAssertEqual(try! MemberModel.fetchCount(db), 1)

            let group = try! GroupModel.fetchExpect(db)
            let epoch = try! EpochModel.fetchExpect(db)
            let member = try! MemberModel.fetchExpect(db)
            let acceptEvent = try! PendingEvent.fetchExpectLatest(db)
            let metadata = try MetadataModel.fetchExpect(db)
            return (group, epoch, member, acceptEvent, metadata)
        }

        XCTAssertEqual(group.id, groupId)
        XCTAssertEqual(group.name, "My Test Group")

        XCTAssertEqual(epoch.groupId, groupId)
        XCTAssertEqual(epoch.id, groupCreatePayload.epoch.epochId)

        XCTAssertEqual(member.groupId, groupId)
        XCTAssertEqual(member.userId, userId)

        XCTAssertEqual(metadata.id, groupId)
        XCTAssertEqual(metadata.epochId, epoch.id)

        let acceptPayload = try! InviteAcceptPayload.decode(from: acceptEvent)
        XCTAssertEqual(acceptPayload.token, inviteBundle.invite.token)
        XCTAssertEqual(acceptPayload.member.groupId, inviteBundle.group.groupId)
        XCTAssertEqual(acceptPayload.member.userId, userId)
    }
}

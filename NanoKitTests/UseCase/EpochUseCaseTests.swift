//
//  EpochUseCaseTests.swift
//  NanoKitTests
//
//  Created by Richard Henry on 3/29/24.
//

import CryptoKit
import NanoCrypto
import XCTest

@testable import NanoKit

final class EpochUseCaseTests: SessionContextTestCase {
    func testCreateDeriveNext() async {
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

        let initialEpoch = try! await dataStore.read { db in
            try EpochModel.fetchExpect(db)
        }

        try! await EpochCreateUseCase(dataStore: dataStore, keychainStorage: keychainStorage)
            .createNext(from: initialEpoch)

        let event = try! await dataStore.read { db in
            XCTAssertEqual(try! EpochModel.fetchCount(db), 1)

            return try! PendingEvent.fetchExpectLatest(db)
        }

        let payload = try! EpochCreatePayload.decode(from: event)

        XCTAssertEqual(payload.epoch.groupId, groupId)
        XCTAssertEqual(payload.epoch.sequenceId, 1)
        XCTAssertEqual(payload.entropy.count, 1)
        XCTAssertEqual(payload.epoch.previousEpoch?.epochId, initialEpoch.id)

        let entropy = payload.entropy[0]
        XCTAssertEqual(entropy.recipientType, .member)
        XCTAssertEqual(entropy.recipientId.asType(), userId)

        try! await EpochDeriveNextUseCase(
            bundle: EpochBundlePayload(
                epoch: payload.epoch,
                ciphertext: entropy.ciphertext
            ),
            dataStore: dataStore,
            keychainStorage: keychainStorage
        )
        .run()

        let epochs = try! await dataStore.read { db in
            try EpochModel.fetchAll(db, groupId: groupId, includeDiscontiguous: false)
        }

        XCTAssertEqual(epochs.count, 2)

        XCTAssertEqual(epochs[0].groupId, groupId)
        XCTAssertEqual(epochs[0].sequenceId, 0)

        XCTAssertEqual(epochs[1].groupId, groupId)
        XCTAssertEqual(epochs[1].sequenceId, 1)

        XCTAssertNotEqual(epochs[0].id, epochs[1].id)
    }
}

final class EpochDeriveUseCaseTests: XCTestCase {
    func testDeriveChainingKeys() {
        let rootKey = SymmetricKey(size: .bits256)
        let (chainingKey, preSharedKey) = EpochDeriveUseCase.deriveChainingKeys(
            previousRootKey: rootKey,
            nextEpochId: EpochID()
        )
        XCTAssertEqual(chainingKey.bitCount, 256)
        XCTAssertEqual(preSharedKey.bitCount, 256)
    }

    func testDeriveNextRootKey() {
        let entropy = SymmetricKey(size: .bits256)
        let chainingKey = SymmetricKey(size: .bits256)
        let nextRootKey = EpochDeriveUseCase.deriveNextRootKey(
            newEntropy: entropy,
            chainingKey: chainingKey
        )
        XCTAssertEqual(nextRootKey.bitCount, 256)
    }
}

//
//  MemberRecoveryUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/26/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

struct MemberRecoveryUseCase: UseCase {
    public var bundle: MemberRecoveryBundlePayload
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    init(
        bundle: MemberRecoveryBundlePayload,
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.bundle = bundle
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        guard bundle.member.state == .live else {
            throw error("Group member in recovery bundle is not live.")
        }

        let (existing, session, userKey) = try await dataStore.read { db in
            let existing = try GroupModel.fetchOne(db, id: bundle.group.groupId)
            let session = try SessionModel.fetchExpect(db)
            let userKey = try UserKeyModel.fetchExpect(db, id: session.userId)
            return (existing, session, userKey)
        }

        guard existing == nil || existing?.isPending == true else {
            log(.info, "Group already exists, ignoring. Group ID: \(bundle.group.groupId)")
            return
        }

        let recoveryKey: SymmetricKey = try keychainStorage.get(.recoveryKey(session.userId))

        try bundle.member.validateSignature(with: userKey)

        try await SecretSaveUseCase(
            userId: session.userId,
            secret: bundle.secret,
            dataStore: dataStore,
            keychainStorage: keychainStorage
        )
        .run()

        let secrets = try bundle.recovery.decryptSecrets(recoveryKey: recoveryKey)

        var rootKeys = [bundle.recovery.metadataEpochId: secrets.metadataEpochRootKey]
        rootKeys[bundle.recovery.epochId] = secrets.epochRootKey

        let member = try MemberModel(payload: bundle.member)

        let (group, metadata, epochs) = try await GroupBootstrapUseCase(
            group: bundle.group,
            // Group is not pending because the server has provided the canonical member record already.
            groupIsPending: false,
            member: member,
            metadata: bundle.metadata,
            bundles: bundle.epochs,
            rootKeys: rootKeys,
            storeKey: try keychainStorage.get(
                .memberStoreKey(session.userId, bundle.group.groupId)
            ),
            storeKeyKyber: try keychainStorage.get(
                .memberStoreKeyKyber(session.userId, bundle.group.groupId)
            ),
            dataStore: dataStore,
            keychainStorage: keychainStorage
        )
        .run()

        try await dataStore.write { db in
            try group.save(db)
            try metadata.save(db)
            try epochs.forEach { try $0.save(db) }
            try member.insert(db, onConflict: .ignore)
        }
    }
}

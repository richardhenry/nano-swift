//
//  GroupBootstrapUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/27/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto
import OrderedCollections

public struct GroupBootstrapUseCase: UseCase {
    public var group: GroupPayload
    public var groupIsPending: Bool
    public var member: MemberModel
    public var metadata: MetadataPayload
    public var bundles: [EpochBundlePayload]
    public var rootKeys: [EpochID: SymmetricKey]
    public var storeKey: Curve25519.KeyAgreement.PrivateKey
    public var storeKeyKyber: Kyber1024.PrivateKey
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        group: GroupPayload,
        groupIsPending: Bool,
        member: MemberModel,
        metadata: MetadataPayload,
        bundles: [EpochBundlePayload],
        rootKeys: [EpochID: SymmetricKey],
        storeKey: Curve25519.KeyAgreement.PrivateKey,
        storeKeyKyber: Kyber1024.PrivateKey,
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.group = group
        self.groupIsPending = groupIsPending
        self.member = member
        self.metadata = metadata
        self.bundles = bundles
        self.rootKeys = rootKeys
        self.storeKey = storeKey
        self.storeKeyKyber = storeKeyKyber
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws -> (GroupModel, MetadataModel, [EpochModel]) {
        let (metadataSigningKey, epochSigningKeys) = try await dataStore.read { db in
            let metadataSigningKey = try metadata.fetchSigningKey(db)
            let epochSigningKeys = try bundles.reduce(into: [EpochID: UserKeyModel]()) {
                $0[$1.epoch.epochId] = try $1.epoch.fetchSigningKey(db)
            }
            return (metadataSigningKey, epochSigningKeys)
        }

        try metadata.validateSignature(with: metadataSigningKey)

        var epochs = OrderedDictionary<EpochID, EpochModel>()

        for bundle in bundles {
            try bundle.epoch.validateSignature(with: epochSigningKeys[bundle.epoch.epochId]!)

            let epoch: EpochModel

            if let rootKey = rootKeys[bundle.epoch.epochId] {
                if bundle.epoch.sequenceId > 0 {
                    if let previousEpoch = bundle.epoch.previousEpoch {
                        let previousRootKey = try previousEpoch.decryptRootKey(nextRootKey: rootKey)
                        try keychainStorage.save(
                            previousRootKey,
                            to: .epochRootKey(previousEpoch.epochId)
                        )
                    } else {
                        throw error("Missing previous root key.")
                    }
                }

                try keychainStorage.save(rootKey, to: .epochRootKey(bundle.epoch.epochId))

                epoch = EpochModel(
                    payload: bundle.epoch,
                    isDiscontiguous: bundle.discontiguous == true
                )
            } else {
                guard let previousEpochId = bundle.epoch.previousEpoch?.epochId,
                    let previousEpoch = epochs[previousEpochId]
                else {
                    throw error("Missing previous epoch.")
                }

                epoch = try await EpochDeriveNextUseCase(
                    bundle: bundle,
                    member: member,
                    dataStore: dataStore,
                    keychainStorage: keychainStorage
                )
                .deriveNext(
                    previousEpoch: previousEpoch,
                    storeKey: storeKey,
                    storeKeyKyber: storeKeyKyber
                )
            }

            epochs[epoch.id] = epoch
        }

        let metadataKey = try MetadataPayload.deriveMetadataKey(
            epochId: metadata.epochId,
            epochRootKey: try keychainStorage.get(.epochRootKey(metadata.epochId))
        )

        let metadataContent = try metadata.decrypt(metadataKey: metadataKey)

        let group = GroupModel(
            id: group.groupId,
            name: metadataContent.name,
            image: metadataContent.image,
            emoji: metadataContent.emoji,
            isPending: groupIsPending,
            badgeTimestamp: group.timestamp
        )

        assert(epochs.count == bundles.count)

        return (
            group,
            MetadataModel(id: group.id, epochId: metadata.epochId),
            Array(epochs.values)
        )
    }
}

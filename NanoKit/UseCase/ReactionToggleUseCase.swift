//
//  ReactionToggleUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/7/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public struct ReactionToggleUseCase: UseCase {
    public var groupId: GroupID
    public var targetId: MessageID
    public var base: String
    public var variation: String?
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        groupId: GroupID,
        targetId: MessageID,
        base: String,
        variation: String?,
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.groupId = groupId
        self.targetId = targetId
        self.base = base
        self.variation = variation
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        let (session, existing, message, epoch) = try await dataStore.read { db in
            let session = try SessionModel.fetchExpect(db)

            let message = try MessageModel.fetchExpect(
                db,
                groupId: groupId,
                id: targetId
            )

            let existing = try ReactionModel.fetchOne(
                db,
                groupId: groupId,
                targetId: targetId,
                userId: session.userId,
                base: base
            )

            let epoch = try EpochModel.fetchCurrent(db, groupId: message.groupId)

            return (session, existing, message, epoch)
        }

        let signingKey: Curve25519.Signing.PrivateKey = try keychainStorage.get(
            .userSigningKey(session.userId)
        )

        let reaction: ReactionModel
        let pendingEvent: PendingEvent

        if var existing = existing {
            // Reaction remove.

            existing.base = nil
            existing.variation = nil
            existing.sendState = .pendingDelete
            reaction = existing

            let payload = try MessageDeletePayload(
                deleting: .reaction(reaction),
                deletedByUserId: session.userId,
                signingKey: signingKey
            )

            pendingEvent = try PendingEvent(
                eventType: .messageDelete,
                payload: payload
            )
        } else {
            // Reaction create.

            reaction = ReactionModel(
                groupId: message.groupId,
                id: MessageID(),
                threadId: message.threadId,
                userId: session.userId,
                targetId: targetId,
                base: base,
                variation: variation,
                sendState: .pendingCreate,
                createTimestamp: .now(),
                editTimestamp: nil
            )

            let payload = try MessageUpdatePayload(
                encrypting: .reaction(reaction),
                inEpoch: epoch,
                senderUserId: session.userId,
                signingKey: signingKey
            )

            pendingEvent = try PendingEvent(
                eventType: .messageCreate,
                payload: payload
            )
        }

        try await dataStore.write { db in
            switch reaction.sendState {
            case .pendingCreate:
                try reaction.save(db)
            case .pendingDelete:
                try ReactionModel.setSendState(
                    db,
                    groupId: reaction.groupId,
                    id: reaction.id,
                    newValue: .pendingDelete
                )
            case .sent:
                throw error("Encountered an unexpected reaction send state.")
            }

            try pendingEvent.save(db)
        }
    }
}

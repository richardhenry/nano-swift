//
//  GroupEditUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 3/29/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public struct GroupEditUseCase: UseCase {
    public var groupId: GroupID
    public var name: String
    public var image: LocalAttachment?
    public var emoji: String?
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        groupId: GroupID,
        name: String,
        image: LocalAttachment?,
        emoji: String?,
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.groupId = groupId
        self.name = name
        self.image = image
        self.emoji = emoji
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        let name = name.trimmingCharacters(in: .whitespaces)

        guard !name.isEmpty else {
            throw error("Group name must not be empty.")
        }

        let (session, userKey, epoch) = try await dataStore.read { db in
            let session = try SessionModel.fetchExpect(db)
            let userKey = try UserKeyModel.fetchExpect(db, id: session.userId)
            let epoch = try EpochModel.fetchCurrent(db, groupId: self.groupId)
            return (session, userKey, epoch)
        }

        let signingKey: Curve25519.Signing.PrivateKey =
            try keychainStorage
            .get(.userSigningKey(userKey.id))

        let epochRootKey: SymmetricKey =
            try keychainStorage
            .get(.epochRootKey(epoch.id))

        let encryptedImage = try await Self.prepareImage(image: image)

        let content = MetadataPayload.Content(
            name: name,
            image: encryptedImage,
            emoji: emoji
        )

        let metadataPayload = try MetadataPayload(
            groupId: groupId,
            encrypting: content,
            inEpoch: epoch,
            epochRootKey: epochRootKey,
            userId: session.userId,
            signingKey: signingKey
        )

        let pendingEvent = try PendingEvent(
            eventType: .metadataUpdate,
            payload: metadataPayload
        )

        try await dataStore.write { db in
            try pendingEvent.save(db)
        }

        try await pendingEvent
            .result(expect: .metadataRecord)
    }

    public static func prepareImage(image: LocalAttachment?) async throws -> EncryptedAttachment? {
        guard let image else { return nil }

        if case .localFile(let file) = image.content {
            let attachment = EncryptedAttachment(file: file)

            let localDirectory = try FileManager.default.secureAppGroupDirectory(
                path: "PendingAttachment"
            )

            try await attachment.encrypt(
                sourceFile: file,
                intoDirectory: localDirectory
            )

            try await FileUpload(fileType: .attachment, localURL: attachment.localURL).send()

            return attachment
        } else if case .encryptedAttachment(let attachment) = image.source {
            return attachment
        } else {
            throw error("Unable to prepare attachment from source: \(image)")
        }
    }
}

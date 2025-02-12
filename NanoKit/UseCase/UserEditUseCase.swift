//
//  UserEditUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 5/29/24.
//

import Foundation
import NanoCore
import NanoCrypto

public struct UserEditUseCase: UseCase {
    public var name: String
    public var image: LocalAttachment?
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        name: String,
        image: LocalAttachment?,
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.name = name
        self.image = image
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        let user = try await dataStore.read { db in
            let session = try SessionModel.fetchExpect(db)
            let user = try UserModel.fetchExpect(db, id: session.userId)
            return user
        }

        let name = name.trimmingCharacters(in: .whitespaces)

        guard !name.isEmpty else {
            throw error("Name must not be empty.")
        }

        let assetKey = try await Self.prepareImage(image: image)

        let userPayload = UserPayload(
            userId: user.id,
            name: name,
            image: assetKey,
            timestamp: .now()
        )

        let pendingEvent = try PendingEvent(
            eventType: .userUpdate,
            payload: userPayload
        )

        try await dataStore.write { db in
            try pendingEvent.save(db)
        }

        try await pendingEvent
            .result(expect: .userRecord)
    }

    public static func prepareImage(image: LocalAttachment?) async throws -> String? {
        guard let image else { return nil }

        if case .localFile(let file) = image.content {
            let localDirectory = try FileManager.default.secureAppGroupDirectory(
                path: "PendingPublicImage"
            )

            let assetKey = FileManager.default.randomFilename()
            var localAssetURL = localDirectory.appendingPathComponent(assetKey)

            let imageData = try Data(contentsOf: file.url)

            guard let image = PlatformImage(data: imageData) else {
                throw error("Unable to load image from file.")
            }

            try image.writeHEIFDataOriented(to: localAssetURL, compressionQuality: 0.9)
            try FileManager.default.makeSecure(&localAssetURL)

            try await FileUpload(fileType: .publicHeic, localURL: localAssetURL).send()

            return assetKey + ".heic"
        } else if case .publicImage(assetKey: let assetKey) = image.source {
            return assetKey
        } else {
            throw error("Unable to prepare public image from source: \(image)")
        }
    }
}

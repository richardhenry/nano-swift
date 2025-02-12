//
//  PendingAttachmentUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/8/24.
//

import Foundation
import NanoCrypto

public struct PendingAttachmentUseCase: UseCase {
    public var pendingAttachment: PendingAttachment
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public func run() async throws {
        let localURL = try FileManager.default
            .secureAppGroupDirectory(path: "PendingAttachment")
            .appending(component: pendingAttachment.assetKey, directoryHint: .notDirectory)

        try await FileUpload(fileType: .attachment, localURL: localURL).send()

        var pendingAttachment = pendingAttachment
        pendingAttachment.isUploadComplete = true

        let isFinished = try await dataStore.write { [pendingAttachment] db in
            try pendingAttachment.save(db)
            return try PendingAttachment.fetchIncompleteCount(
                db,
                groupId: pendingAttachment.groupId,
                messageId: pendingAttachment.messageId
            ) == 0
        }

        try FileManager.default.removeItem(at: localURL)

        guard isFinished else {
            // Waiting on other attachments to finish uploading.
            return
        }

        try await MessageSendDeferredUseCase(
            groupId: pendingAttachment.groupId,
            messageId: pendingAttachment.messageId,
            dataStore: dataStore,
            keychainStorage: keychainStorage
        )
        .run()
    }
}

extension PendingAttachmentUseCase: UseCaseErrorHandler {
    public func handleError(_ error: any Error) async throws {
        try await dataStore.write { db in
            try MessageModel.setSendState(
                db,
                groupId: pendingAttachment.groupId,
                id: pendingAttachment.messageId,
                newValue: .failed
            )
        }
    }
}

//
//  MessageAttachmentUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/8/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public struct MessageAttachmentUseCase: UseCase {
    public var groupId: GroupID
    public var messageId: MessageID
    public var attachmentPicker: AttachmentPicker
    public var links: [LinkProvider]

    public init(
        groupId: GroupID,
        messageId: MessageID,
        attachmentPicker: AttachmentPicker,
        links: [LinkProvider]
    ) {
        self.groupId = groupId
        self.messageId = messageId
        self.attachmentPicker = attachmentPicker
        self.links = links
    }

    public func run() async throws -> ([EncryptedAttachment], [LinkPreview], [PendingAttachment]) {
        guard !attachmentPicker.isEmpty || !links.isEmpty else {
            return ([], [], [])
        }

        guard links.allSatisfy({ !$0.isFetching }) else {
            throw error("Link(s) are not ready.")
        }

        guard attachmentPicker.attachments.allSatisfy({ $0.isLoaded }) else {
            throw error("Attachment(s) are not ready.")
        }

        var attachments = [EncryptedAttachment]()
        var linkPreviews = [LinkPreview]()
        var pendingAttachments = [PendingAttachment]()

        let localDirectory = try FileManager.default.secureAppGroupDirectory(
            path: "PendingAttachment"
        )

        try await withThrowingDiscardingTaskGroup { group in
            func addTask(_ file: any SecureTemporaryFile, _ attachment: EncryptedAttachment) {
                let targetURL =
                    localDirectory
                    .appending(component: attachment.assetKey, directoryHint: .notDirectory)

                group.addTask {
                    let paddedURL = try FileManager.default.randomSecureTemporaryFile()

                    try await PadmeFileStream().pad(source: file.url, target: paddedURL)

                    try await XChaChaPolyFileStream()
                        .encrypt(
                            source: paddedURL,
                            target: targetURL,
                            key: attachment.encryptionKey.rawValue
                        )

                    try? FileManager.default.removeItem(at: paddedURL)
                }
            }

            for provider in links {
                switch provider.source {
                case .request(let request):
                    var linkPreview = LinkPreview(
                        url: request.url,
                        title: request.title,
                        summary: request.summary
                    )

                    if let file = request.image {
                        let (attachment, pendingAttachment) = prepare(file)

                        group.addTask {
                            try await attachment.encrypt(
                                sourceFile: file,
                                intoDirectory: localDirectory
                            )
                        }

                        linkPreview.image = attachment
                        pendingAttachments.append(pendingAttachment)
                    }

                    if let file = request.icon {
                        let (attachment, pendingAttachment) = prepare(file)

                        group.addTask {
                            try await attachment.encrypt(
                                sourceFile: file,
                                intoDirectory: localDirectory
                            )
                        }

                        linkPreview.icon = attachment
                        pendingAttachments.append(pendingAttachment)
                    }

                    linkPreviews.append(linkPreview)

                case .preview(let linkPreview):
                    linkPreviews.append(linkPreview)
                }
            }

            for value in attachmentPicker.attachments {
                if case .localFile(let file) = value.content {
                    let (attachment, pendingAttachment) = prepare(file)

                    group.addTask {
                        try await attachment.encrypt(
                            sourceFile: file,
                            intoDirectory: localDirectory
                        )
                    }

                    attachments.append(attachment)
                    pendingAttachments.append(pendingAttachment)

                } else if case .encryptedAttachment(let attachment) = value.source {
                    attachments.append(attachment)

                } else {
                    log(.warning, "Unable to prepare attachment from: \(value)")
                    continue
                }
            }
        }

        return (attachments, linkPreviews, pendingAttachments)
    }

    func prepare(_ file: any SecureTemporaryFile) -> (EncryptedAttachment, PendingAttachment) {
        let attachment = EncryptedAttachment(file: file)

        let pendingAttachment = PendingAttachment(
            groupId: groupId,
            messageId: messageId,
            assetKey: attachment.assetKey
        )

        return (attachment, pendingAttachment)
    }
}

//
//  ComposeViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/8/24.
//

import CryptoKit
import Foundation
import NanoKit

#if os(iOS)
import Nano_iOS
#elseif os(macOS)
import Nano_Mac
#endif

@Observable final class ComposeViewModel: FormViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var formPhase: FormPhase = .fetching

    let groupId: GroupID
    let threadId: ThreadID
    let isRoot: Bool
    let existingMessage: MessageModel?

    let attachmentPicker = AttachmentPicker()
    let mentionPicker: MentionPickerViewModel

    var messageId: MessageID
    var links = [LinkProvider]()

    var isEnabled = true
    var isTextEmpty = true

    var isCameraVisible = false
    var isPhotoPickerVisible = false
    var isFilePickerVisible = false

    var textCoordinator: MessageTextViewCoordinator? {
        didSet {
            guard oldValue == nil,
                let textCoordinator,
                let text = existingMessage?.text
            else {
                return
            }
            textCoordinator.insertText(text)
        }
    }

    var isSendEnabled: Bool {
        return isEnabled
            && (!isTextEmpty
                || !attachmentPicker.isEmpty
                || !links.isEmpty)
    }

    init(groupId: GroupID, existingThreadId: ThreadID?) {
        self.groupId = groupId
        messageId = MessageID()
        existingMessage = nil

        if let existingThreadId {
            threadId = existingThreadId
            isRoot = false
        } else {
            threadId = ThreadID()
            isRoot = true
        }

        mentionPicker = MentionPickerViewModel(groupId: groupId)
        mentionPicker.compose = self
    }

    init(existingMessage message: MessageModel) {
        groupId = message.groupId
        messageId = message.id
        threadId = message.threadId
        isRoot = message.isRoot
        existingMessage = message
        mentionPicker = MentionPickerViewModel(groupId: groupId)
        mentionPicker.compose = self
    }

    func performFetch() async throws {
        if let message = existingMessage {
            if let value = message.attachments?.map({ LocalAttachment($0) }) {
                attachmentPicker.attachments = value
            }

            if let value = message.links?.compactMap({ LinkProvider(preview: $0) }) {
                links = value
            }
        }
    }

    func performSubmit() async throws {
        let (text, mentions) = try await MainActor.run {
            try prepareText()
        }

        try await MessageSendUseCase(
            groupId: groupId,
            messageId: messageId,
            threadId: threadId,
            isRoot: isRoot,
            text: text,
            attachmentPicker: attachmentPicker,
            links: links,
            mentions: mentions
        )
        .run()
    }

    func shouldComplete() throws -> Bool {
        guard !isRoot, existingMessage == nil else {
            return true
        }

        messageId = MessageID()
        textCoordinator?.clearText()
        attachmentPicker.reset()
        links.removeAll()
        return false
    }
}

//
//  NotificationService.swift
//  NanoNotificationService
//
//  Created by Richard Henry on 1/27/24.
//

import MessagePack
import NanoCore
import NanoKit
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    var currentTask: Task<(), Error>?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if bestAttemptContent?.title == "New Message" {
            // Replace text with localized fallback text.
            bestAttemptContent?.title = String(localized: "New Message")
            bestAttemptContent?.body = String(localized: "You have a new message.")
        }

        currentTask = Task {
            do {
                try await handle(request: request)
            } catch {
                log(error)
            }

            guard !Task.isCancelled, let content = bestAttemptContent else {
                return
            }

            contentHandler(content)
            currentTask = nil
        }
    }

    override func serviceExtensionTimeWillExpire() {
        currentTask?.cancel()
        currentTask = nil

        if let contentHandler = contentHandler, let content = bestAttemptContent {
            contentHandler(content)
        }
    }

    func handle(request: UNNotificationRequest) async throws {
        guard let base64Encoded = request.content.userInfo["ctx"] as? String, !base64Encoded.isEmpty
        else {
            throw error("Missing 'ctx' key.")
        }

        guard let data = Data(base64Encoded: base64Encoded) else {
            throw error("Base64 decoding failed.")
        }

        let event = try MessagePackDecoder().decode(ServerEvent.self, from: data)

        var messagePayload: MessagePayload?
        for result in try await event.handle() {
            if let payload = result.payload as? MessagePayload {
                messagePayload = payload
            }
        }

        if let payload = messagePayload {
            let (message, user, thread, group) = try await DataStore.shared.read { db in
                let message = try MessageModel.fetchOne(
                    db,
                    groupId: payload.groupId,
                    id: payload.messageId
                )
                let user = try UserModel.fetchOne(db, id: payload.userId)
                let thread = try ThreadModel.fetchOne(
                    db,
                    groupId: payload.groupId,
                    id: payload.threadId
                )
                let group = try GroupModel.fetchOne(db, id: payload.groupId)
                return (message, user, thread, group)
            }

            bestAttemptContent?.title = GroupModel.renderName(group)
            bestAttemptContent?.subtitle = ThreadModel.renderSubject(thread)
            bestAttemptContent?.body =
                message?.renderPlaintext(user: user) ?? String(localized: "You have a new message.")

            if let message = message {
                bestAttemptContent?.userInfo["target"] = NotificationTarget(message: message)
                    .base64EncodedString()
            }
        }
    }
}

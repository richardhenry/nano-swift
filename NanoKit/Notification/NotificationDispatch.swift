//
//  NotificationDispatch.swift
//  NanoKit
//
//  Created by Richard Henry on 1/28/24.
//

import Combine
import Foundation
import MessagePack
import NanoCore
import UserNotifications

@available(iOS, unavailable)
public final class NotificationDispatch {
    public static let shared = NotificationDispatch()

    private var queue = DispatchQueue(label: "NotificationDispatch")
    private var cancellables = Set<AnyCancellable>()
    private var connectTimestamp: Timestamp = .max

    public init() {
        MessageModel.insertSubject
            .receive(on: queue)
            .sink { [weak self] message in
                guard let self = self else { return }

                Task {
                    do {
                        try await self.handle(message: message)
                    } catch {
                        log(error)
                    }
                }
            }
            .store(in: &cancellables)

        Sock.shared.connectSubject
            .receive(on: queue)
            .sink { [weak self] _ in
                self?.connectTimestamp = Timestamp()
            }
            .store(in: &cancellables)
    }

    private func handle(message: MessageModel) async throws {
        let session = try await DataStore.shared.read { db in
            try SessionModel.fetchExpect(db)
        }

        guard message.userId != session.userId,
            message.createTimestamp > connectTimestamp
        else {
            return
        }

        let (user, group, thread, notifs, visibility) = try await DataStore.shared.read { db in
            let user = try UserModel.fetchOne(db, id: message.userId)
            let group = try GroupModel.fetchExpect(db, id: message.groupId)
            let thread = try ThreadModel.fetchExpect(
                db,
                groupId: message.groupId,
                id: message.threadId
            )
            let notifs: GroupNotifsValue = try GroupSettingModel.fetchValue(
                db,
                groupId: message.groupId,
                settingType: .notifs,
                defaultValue: .default
            )
            let visibility: ThreadVisibilityValue = try ThreadSettingModel.fetchValue(
                db,
                groupId: message.groupId,
                threadId: message.threadId,
                settingType: .visibility,
                defaultValue: .default
            )
            return (user, group, thread, notifs, visibility)
        }

        guard shouldNotify(notifs, visibility) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = GroupModel.renderName(group)
        content.subtitle = ThreadModel.renderSubject(thread)
        content.body = message.renderPlaintext(user: user)
        content.sound = .default
        content.userInfo["target"] = NotificationTarget(message: message).base64EncodedString()

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    private func shouldNotify(
        _ notifs: GroupNotifsValue,
        _ visibility: ThreadVisibilityValue
    ) -> Bool {
        switch notifs {
        case .off:
            return false
        case .allMessages:
            return visibility != .archived
        case .onlyStarredThreads:
            return visibility == .starred
        }
    }
}

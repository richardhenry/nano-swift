//
//  NotificationHandler.swift
//  Nano
//
//  Created by Richard Henry on 1/30/24.
//

import NanoCore
import NanoKit
import UserNotifications

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationHandler()

    @Published var target: NotificationTarget?

    override init() {
        log(
            .info,
            "Configured with remote host: \(Request.baseURL) User agent: \(Request.userAgent)"
        )
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        let options: UNAuthorizationOptions = [
            .alert, .badge, .sound, .providesAppNotificationSettings,
        ]
        UNUserNotificationCenter.current()
            .requestAuthorization(options: options) {
                success,
                error in
                log(.info, "Request authorization: \(success) Error: \(error)")
            }

        #if os(iOS)
        UIApplication.shared.registerForRemoteNotifications()
        #elseif os(macOS)
        NSApplication.shared.registerForRemoteNotifications()
        #endif
    }

    func sendDeviceToken(_ deviceToken: Data) async {
        do {
            let session = try await DataStore.shared.read { db in
                try SessionModel.fetchExpect(db)
            }

            let payload = PushPayload(
                userId: session.userId,
                sessionId: session.sessionId,
                token: deviceToken,
                timestamp: .now()
            )

            let pendingEvent = try PendingEvent(
                eventType: .pushRegister,
                payload: payload
            )

            try await DataStore.shared.write { db in
                try pendingEvent.save(db)
            }
        } catch {
            log(error)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
            Void
    ) {
        log(.debug, "Will present: \(notification)")

        Task.detached {
            if let target = NotificationTarget(decodeFrom: notification) {
                await MainActor.run {
                    if AppState.shared.isActive,
                        case .message(let groupId, let threadId, _) = target,
                        VisibilityState.shared.isVisible(ThreadPath(groupId, threadId))
                    {
                        completionHandler([])
                    } else {
                        completionHandler([.list, .banner, .sound])
                    }
                }
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        log(.debug, "Did receive: \(response)")

        Task.detached { [weak self] in
            if let self = self, let target = NotificationTarget(decodeFrom: response.notification) {
                await MainActor.run {
                    self.target = target
                    completionHandler()
                }
                log(.debug, "Notification target is: \(target)")
            } else {
                await MainActor.run {
                    completionHandler()
                }
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        openSettingsFor notification: UNNotification?
    ) {
        log(.debug, "Notification settings requested.")
    }
}

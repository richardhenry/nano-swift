//
//  NotificationTarget.swift
//  NanoKit
//
//  Created by Richard Henry on 1/30/24.
//

import Foundation
import MessagePack
import UserNotifications

public enum NotificationTarget: Codable {
    case message(GroupID, ThreadID, MessageID)

    public init(message: MessageModel) {
        self = .message(message.groupId, message.threadId, message.id)
    }

    public init?(decodeFrom notification: UNNotification) {
        if let base64String = notification.request.content.userInfo["target"] as? String,
            let data = Data(base64Encoded: base64String),
            let decoded = try? MessagePackDecoder().decode(NotificationTarget.self, from: data)
        {
            self = decoded
        } else {
            return nil
        }
    }

    public func base64EncodedString() -> String {
        try! MessagePackEncoder().encode(self).base64EncodedString()
    }
}

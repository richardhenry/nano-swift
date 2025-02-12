//
//  AppDelegate.swift
//  Nano
//
//  Created by Richard Henry on 1/26/24.
//

import CryptoKit
import NanoCore
import NanoKit

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS)
final class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        log(.debug, "APNs device token: \(deviceToken.map { String(format: "%02x", $0) }.joined())")
        Task.detached { await NotificationHandler.shared.sendDeviceToken(deviceToken) }
    }
}
#elseif os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    override init() {
        super.init()
        UserDefaults.standard.setValue(300, forKey: "NSInitialToolTipDelay")
    }

    func application(
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        log(.debug, "APNs device token: \(deviceToken.map { String(format: "%02x", $0) }.joined())")
        Task.detached { await NotificationHandler.shared.sendDeviceToken(deviceToken) }
    }
}
#endif

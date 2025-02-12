//
//  NanoApp.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

import NanoCore
import NanoKit
import SwiftUI

@main
enum Main {
    static func main() throws {
        if !isRunningInTests() {
            NanoApp.main()
        } else {
            TestApp.main()
        }
    }
}

struct NanoApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif

    let logger = Logger.shared
    let appState = AppState.shared
    let sock = Sock.shared
    let fetchCoordinator = FetchCoordinator.shared
    let notificationHandler = NotificationHandler.shared
    let eventHandler = EventHandler.shared
    #if os(macOS)
    let notificationDispatch = NotificationDispatch.shared
    #endif
    let commandDispatch = CommandDispatch.shared
    let visibilityState = VisibilityState.shared

    var body: some Scene {
        WindowGroup {
            SessionWrapperView()
                .nanoAppearance()
                .environmentObject(appState)
                .environmentObject(notificationHandler)
                .environmentObject(commandDispatch)
                .environment(DataStore.shared)
                .environment(visibilityState)
        }
        .commands {
            NanoCommands()
        }

        #if os(macOS)
        Settings {
            NavigationStack {
                SettingsView()
            }
            .nanoAppearance()
            .frame(minWidth: 360, minHeight: 512)
            .environment(DataStore.shared)
        }
        #endif
    }
}

struct TestApp: App {
    var body: some Scene {
        WindowGroup {}
    }
}

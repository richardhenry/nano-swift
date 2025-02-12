//
//  AppState.swift
//  Nano
//
//  Created by Richard Henry on 1/21/24.
//

import Combine
import Foundation
import NanoCore

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public final class AppState: ObservableObject {
    public static let shared = AppState()

    @Published public var isActive: Bool
    @Published public var isUpdateRequired = false

    private var cancellables = Set<AnyCancellable>()

    public init() {
        #if os(iOS)
        isActive = UIApplication.shared.applicationState == .active

        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.isActive = true
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.isActive = false
            }
            .store(in: &cancellables)

        // Handle changes to the db from the notification service process while the app was not active.
        $isActive
            .sink { isActive in
                guard isActive else { return }

                Task.detached(priority: .userInitiated) {
                    do {
                        try await DataStore.shared.write { db in
                            try db.notifyChanges(in: .fullDatabase)
                        }
                    } catch {
                        log(error)
                    }
                }
            }
            .store(in: &cancellables)
        #elseif os(macOS)
        isActive = NSApplication.shared.isActive

        NotificationCenter.default
            .publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.isActive = true
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: NSApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.isActive = false
            }
            .store(in: &cancellables)
        #endif

        MessageSendInterruptedUseCase(dataStore: .shared).detachedTask()

        Emoji.asyncLoad(qos: .utility)
    }
}

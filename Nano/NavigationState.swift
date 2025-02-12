//
//  NavigationState.swift
//  Nano
//
//  Created by Richard Henry on 1/28/24.
//

import Combine
import NanoCore
import NanoKit
import SwiftUI

@Observable final class NavigationState {
    var columnVisibility: NavigationSplitViewVisibility = .all

    var groupId: GroupID? {
        didSet {
            log(.info, "Selected group ID: \(groupId)")

            if groupId != oldValue, threadId != nil {
                threadId = nil
            }
        }
    }

    var threadId: ThreadID? {
        didSet {
            log(.info, "Selected thread ID: \(threadId)")
        }
    }

    var navigationPath = NavigationPath() {
        didSet {
            log(.info, "Navigation path: \(navigationPath)")
        }
    }

    #if os(macOS)
    var searchText = ""
    #endif

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationHandler.shared.$target
            .receive(on: RunLoop.main)
            .sink { [weak self] target in
                if let target {
                    self?.handle(target: target)
                }
            }
            .store(in: &cancellables)

        defer {
            if let target = NotificationHandler.shared.target {
                handle(target: target)
            }
        }
    }

    func clear() {
        groupId = nil
        threadId = nil
        navigationPath = NavigationPath()
    }

    func handle(target: NotificationTarget) {
        switch target {
        case .message(let groupId, let threadId, _):
            self.groupId = groupId
            self.threadId = threadId

            var path = NavigationPath()
            path.append(groupId)
            path.append(threadId)
            navigationPath = path
        }
    }
}

//
//  VisibilityState.swift
//  Nano
//
//  Created by Richard Henry on 3/4/24.
//

import Combine
import Foundation
import NanoCore

@Observable public class VisibilityState {
    public static let shared = VisibilityState()

    public let groupDidAppear = PassthroughSubject<GroupID, Never>()
    public let groupDidDisappear = PassthroughSubject<GroupID, Never>()
    public let threadDidAppear = PassthroughSubject<ThreadPath, Never>()
    public let threadDidDisappear = PassthroughSubject<ThreadPath, Never>()

    @MainActor public private(set) var visibleGroups = Set<GroupID>() {
        didSet {
            log(.debug, "Visible groups: \(visibleGroups)")
            visibleGroups.subtracting(oldValue).forEach { groupDidAppear.send($0) }
            oldValue.subtracting(visibleGroups).forEach { groupDidDisappear.send($0) }
        }
    }

    @MainActor public private(set) var visibleThreads = Set<ThreadPath>() {
        didSet {
            log(.debug, "Visible threads: \(visibleThreads)")
            visibleThreads.subtracting(oldValue).forEach { threadDidAppear.send($0) }
            oldValue.subtracting(visibleThreads).forEach { threadDidDisappear.send($0) }
        }
    }

    @MainActor public private(set) var visibleGroupMap = [ViewID: GroupID]() {
        didSet {
            visibleGroups = Set(visibleGroupMap.values)
        }
    }

    @MainActor public private(set) var visibleThreadMap = [ViewID: ThreadPath]() {
        didSet {
            visibleThreads = Set(visibleThreadMap.values)
        }
    }

    @MainActor public func isVisible(_ groupId: GroupID) -> Bool {
        visibleGroups.contains(groupId)
    }

    @MainActor public func isVisible(_ threadPath: ThreadPath) -> Bool {
        visibleThreads.contains(threadPath)
    }

    @MainActor public func setVisible(_ viewId: ViewID, group groupId: GroupID?) {
        log(.trace, "\(viewId) - Group: \(groupId)")
        visibleGroupMap[viewId] = groupId
    }

    @MainActor public func setVisible(_ viewId: ViewID, thread threadPath: ThreadPath?) {
        log(.trace, "\(viewId) - Thread: \(threadPath)")
        visibleThreadMap[viewId] = threadPath
    }
}

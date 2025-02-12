//
//  NanoCommands.swift
//  Nano
//
//  Created by Richard Henry on 2/1/24.
//

import Combine
import NanoKit
import SwiftUI

struct NanoCommands: Commands {
    let commandDispatch = CommandDispatch.shared

    @FocusedBinding(\.selectedGroup) var selectedGroup
    @FocusedBinding(\.selectedThread) var selectedThread

    var body: some Commands {
        SidebarCommands()

        CommandGroup(before: .newItem) {
            Button("New Thread") {
                if let groupId = selectedGroup.flatMap({ $0 }) {
                    commandDispatch.newThread.send(groupId)
                }
            }
            .keyboardShortcut("n")
            .disabled(selectedGroup.flatMap({ $0 }) == nil)
        }
    }
}

final class CommandDispatch: ObservableObject {
    static let shared = CommandDispatch()
    let newThread = PassthroughSubject<GroupID, Never>()
}

private struct SelectedGroupKey: FocusedValueKey {
    typealias Value = Binding<GroupID?>
}

private struct SelectedThreadKey: FocusedValueKey {
    typealias Value = Binding<ThreadID?>
}

extension FocusedValues {
    var selectedGroup: Binding<GroupID?>? {
        get { self[SelectedGroupKey.self] }
        set { self[SelectedGroupKey.self] = newValue }
    }

    var selectedThread: Binding<ThreadID?>? {
        get { self[SelectedThreadKey.self] }
        set { self[SelectedThreadKey.self] = newValue }
    }
}

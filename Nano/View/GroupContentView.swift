//
//  GroupContentView.swift
//  Nano
//
//  Created by Richard Henry on 1/28/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct GroupContentView: View {
    @State private var groupId: GroupID?
    @ViewModel private var viewer: ViewerRoleViewModel
    @ViewModel private var group: GroupViewModel
    @ViewModel private var threads: ThreadListViewModel
    @State private var viewId = ViewID()
    @State private var isVisible = false
    @State private var isThreadCreateVisible = false
    @State private var isInviteListVisible = false
    @State private var isDetailVisible = false
    @State private var searchText = ""
    @EnvironmentObject private var appState: AppState
    @Environment(NavigationState.self) private var navigationState
    @EnvironmentObject private var commandDispatch: CommandDispatch
    @Environment(DataStore.self) private var dataStore
    @Environment(\.openWindow) private var openWindow
    @Environment(VisibilityState.self) private var visibilityState
    @Environment(\.prefersSplitView) private var prefersSplitView

    init(groupId: GroupID? = nil) {
        self.groupId = groupId
        _viewer = ViewerRoleViewModel(groupId: groupId).wrapped()
        _group = GroupViewModel(groupId: groupId).wrapped()
        _threads = ThreadListViewModel(groupId: groupId).wrapped()
    }

    var body: some View {
        @Bindable var navigationState = navigationState

        Group {
            if let threads = threads.value {
                if !threads.isEmpty {
                    List(selection: $navigationState.threadId) {
                        ForEach(threads) { item in
                            switch item {
                            case .thread(let item):
                                ThreadItemView(
                                    thread: item.thread,
                                    visibility: item.visibility,
                                    message: item.message,
                                    user: item.user
                                )
                                .id(item.thread.id)
                            }
                        }
                    }
                    .navigationTitle(GroupModel.renderName(group.value))
                } else {
                    EmptyTextView("No Threads Yet")
                }
            } else {
                EmptyTextView("No Group Selected", isObservingSearch: false)
            }
        }
        .toolbarTitleDisplayMode(.inline)
        #if os(iOS)
        .searchable(text: $threads.searchText)
        #elseif os(macOS)
        .onChange(of: navigationState.searchText) { _, newValue in
            $threads.searchText.wrappedValue = newValue
        }
        #endif
        .onChange(of: navigationState.groupId) { _, newValue in
            if prefersSplitView { groupId = newValue }
        }
        .onChange(of: groupId) { _, newValue in
            viewer.groupId = newValue
            group.groupId = newValue
            threads.groupId = newValue
            updateVisibility()
        }
        .onChange(of: threads.value) { _, newValue in
            updateVisibility()
        }
        .onAppear {
            isVisible = true
            updateVisibility()
        }
        .onDisappear {
            isVisible = false
            updateVisibility()
        }
        .toolbar {
            #if os(iOS)
            if let group = group.value {
                ToolbarItem(placement: .principal) {
                    GroupTitleButton(group: group) {
                        isDetailVisible = true
                    }
                }
            }
            #endif

            ToolbarItemGroup {
                #if os(macOS)
                Button("Group Details", systemImage: "info.circle") {
                    isDetailVisible = true
                }
                .help("View group details")
                .disabled(groupId == nil)
                #endif

                Button("New Thread", systemImage: "square.and.pencil") {
                    isThreadCreateVisible = true
                }
                .disabled(!viewer.isMemberAllowed(.threadCreate, .messageCreate))
                .keyboardShortcut("n")
            }
        }
        .onReceive(commandDispatch.newThread) { groupId in
            if groupId == navigationState.groupId {
                isThreadCreateVisible = true
            }
        }
        .sheet(isPresented: $isThreadCreateVisible) {
            if let groupId {
                NewThreadView(groupId: groupId)
            }
        }
        .sheet(isPresented: $isInviteListVisible) {
            if let groupId {
                InviteListView(groupId: groupId)
            }
        }
        .sheet(isPresented: $isDetailVisible) {
            if let groupId {
                NavigationStack {
                    GroupDetailView(groupId: groupId)
                }
                #if os(macOS)
                .frame(minWidth: 360, minHeight: 512)
                #endif
            }
        }
    }

    private func updateVisibility() {
        guard let groupId, isVisible else {
            visibilityState.setVisible(viewId, group: nil)
            return
        }

        visibilityState.setVisible(viewId, group: groupId)

        Task {
            let readState = ReadStatePayload(
                groupId: groupId,
                threadId: nil,
                timestamp: .now(),
                forceUnread: false
            )

            do {
                let pendingEvent = try PendingEvent(eventType: .readStateUpdate, payload: readState)

                try await DataStore.shared.write { db in
                    try GroupModel.markRead(db, groupId: groupId)
                    try pendingEvent.save(db)
                }
            } catch {
                log(error)
            }
        }
    }
}

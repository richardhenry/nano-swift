//
//  ThreadContentView.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct ThreadContentView: View {
    @State private var groupId: GroupID?
    @State private var threadId: ThreadID?
    @ViewModel private var visibility: ThreadVisibilityViewModel
    @ViewModel private var messages: MessageListViewModel
    @State private var viewId = ViewID()
    @State private var isVisible = false
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @Environment(DataStore.self) private var dataStore
    @Environment(NavigationState.self) private var navigationState
    @Environment(VisibilityState.self) private var visibilityState
    @Environment(\.prefersSplitView) private var prefersSplitView

    init(groupId: GroupID? = nil, threadId: ThreadID? = nil) {
        self.groupId = groupId
        self.threadId = threadId
        _visibility = ThreadVisibilityViewModel(groupId: groupId, threadId: threadId).wrapped()
        _messages = MessageListViewModel(groupId: groupId, threadId: threadId).wrapped()
    }

    var body: some View {
        let defaultInsets = platformValue(
            iOS: EdgeInsets(),
            // List rows on macOS appear to have default horizontal padding, and it's not obvious how to remove it.
            macOS: EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -9)
        )

        let reactionInsets = EdgeInsets(
            top: defaultInsets.top,
            leading: defaultInsets.leading + MessageView.userImageSize
                + MessageView.horizontalSpacing,
            bottom: defaultInsets.bottom,
            trailing: defaultInsets.trailing
        )

        Group {
            if threadId != nil {
                List {
                    #if os(macOS)
                    Spacer()
                        .frame(height: 5)
                        .listRowSeparator(.hidden)
                        .listRowInsets(defaultInsets)
                    #endif

                    ForEach(messages.value) { item in
                        switch item {
                        case .dateBreak(let timestamp):
                            DateBreakView(timestamp: timestamp)
                                .listRowSeparator(.hidden)
                                .listRowInsets(defaultInsets)
                        case .message(let message, let user, let reactions, let header):
                            MessageView(
                                message: message,
                                user: user,
                                header: header
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(defaultInsets)

                            if let reactions = reactions {
                                ReactionStackView(
                                    groupId: message.groupId,
                                    targetId: message.id,
                                    reactions: reactions
                                )
                                .padding(.horizontal)
                                .listRowSeparator(.hidden)
                                .listRowInsets(reactionInsets)
                            }
                        case .deletedMessage(_, let deletedByUser):
                            VStack(alignment: .center) {
                                Text("\(UserModel.renderName(deletedByUser)) deleted a message.")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 5)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .listRowSeparator(.hidden)
                            .listRowInsets(defaultInsets)
                        }
                    }

                    Spacer()
                        .frame(height: 12)
                        .listRowSeparator(.hidden)
                        .listRowInsets(defaultInsets)
                }
                .listStyle(.plain)
            } else {
                EmptyTextView("No Thread Selected", isObservingSearch: false)
            }
        }
        .environment(\.defaultMinListRowHeight, 0)
        .navigationTitle("Thread")
        .toolbarTitleDisplayMode(.inline)
        .onChange(of: navigationState.groupId) { _, newValue in
            if prefersSplitView { groupId = newValue }
        }
        .onChange(of: navigationState.threadId) { _, newValue in
            if prefersSplitView { threadId = newValue }
        }
        .onChange(of: groupId) { _, newValue in
            visibility.groupId = newValue
            messages.groupId = newValue
            updateVisibility()
        }
        .onChange(of: threadId) { _, newValue in
            visibility.threadId = newValue
            messages.threadId = newValue
            updateVisibility()
        }
        .onChange(of: messages.value) { _, newValue in
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
            Button {
                guard let groupId,
                    let threadId,
                    let visibility = visibility.value
                else { return }

                let value: ThreadVisibilityValue =
                    visibility == .starred ? .default : .starred

                ThreadSettingUseCase(
                    groupId: groupId,
                    threadId: threadId,
                    settingType: .visibility,
                    value: value
                )
                .detachedTask()
            } label: {
                if visibility.value == .starred {
                    Label("Unstar Thread", systemImage: "star.fill")
                } else {
                    Label("Star Thread", systemImage: "star")
                }
            }
            .tint(visibility.value == .starred ? .orange : .accent)
            .help(
                visibility.value == .starred
                    ? String(localized: "Unstar this thread")
                    : String(localized: "Star this thread")
            )
            .disabled(groupId == nil || threadId == nil)

            Button {
                guard let groupId,
                    let threadId,
                    let visibility = visibility.value
                else { return }

                let value: ThreadVisibilityValue =
                    visibility == .archived ? .default : .archived

                ThreadSettingUseCase(
                    groupId: groupId,
                    threadId: threadId,
                    settingType: .visibility,
                    value: value
                )
                .detachedTask()
            } label: {
                if visibility.value == .archived {
                    Label("Unarchive Thread", systemImage: "archivebox.fill")
                } else {
                    Label("Archive Thread", systemImage: "archivebox")
                }
            }
            .help(
                visibility.value == .archived
                    ? String(localized: "Unarchive this thread")
                    : String(localized: "Archive this thread")
            )
            .disabled(groupId == nil || threadId == nil)
        }
        .keyboardAccessory {
            if let groupId, let threadId {
                ComposeBarView(groupId: groupId, threadId: threadId)
                    .id(threadId)
            }
        }
    }

    private func updateVisibility() {
        guard let groupId, let threadId, isVisible else {
            visibilityState.setVisible(viewId, thread: nil)
            return
        }

        visibilityState.setVisible(viewId, thread: ThreadPath(groupId, threadId))

        Task {
            let readState = ReadStatePayload(
                groupId: groupId,
                threadId: threadId,
                timestamp: .now(),
                forceUnread: false
            )

            do {
                let pendingEvent = try PendingEvent(eventType: .readStateUpdate, payload: readState)

                try await DataStore.shared.write { db in
                    try ThreadModel.markRead(db, groupId: groupId, id: threadId)
                    try pendingEvent.save(db)
                }
            } catch {
                log(error)
            }
        }
    }
}

#Preview {
    let dataStore = DataStore.preview()
    let groupId = Array(dataStore.previewGroupIdToThreadIds.keys)[0]
    let threadId = dataStore.previewGroupIdToThreadIds[groupId]![0]

    return NavigationStack {
        ThreadContentView(groupId: groupId, threadId: threadId)
    }
    .environment(dataStore)
}

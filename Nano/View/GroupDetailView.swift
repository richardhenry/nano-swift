//
//  GroupDetailView.swift
//  Nano
//
//  Created by Richard Henry on 1/29/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct GroupDetailView: View {
    let groupId: GroupID
    @ViewModel private var group: GroupViewModel
    @ViewModel private var members: MemberListViewModel
    @ViewModel private var viewer: ViewerRoleViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @Environment(NavigationState.self) private var navigationState
    @State private var isTitleViewVisible = false
    @State private var isEditVisible = false
    @State private var isLeaveConfirmationVisible = false
    @State private var isLeavingGroup = false

    init(groupId: GroupID) {
        self.groupId = groupId
        _group = GroupViewModel(groupId: groupId).wrapped()
        _members = MemberListViewModel(groupId: groupId).wrapped()
        _viewer = ViewerRoleViewModel(groupId: groupId).wrapped()
    }

    var body: some View {
        List {
            Section {
                #if os(macOS)
                ZStack(alignment: .topTrailing) {
                    HStack {
                        if viewer.isAdminAllowed(.metadataUpdate) {
                            Button("Edit") {
                                isEditVisible = true
                            }
                        }

                        newEpochButton

                        leaveButton
                    }

                    header
                }
                .listRowSeparator(.hidden)
                #endif

                NavigationLink {
                    GroupNotifsView(groupId: groupId)
                } label: {
                    Label("Notifications", systemImage: "bell")
                        .labelStyle(SettingLabelStyle())
                        .tint(.red)
                }

                if viewer.isMemberAllowed(.inviteCreate) {
                    NavigationLink {
                        InviteListView(groupId: groupId)
                    } label: {
                        Label("Invite Links", systemImage: "link")
                            .labelStyle(SettingLabelStyle())
                            .tint(.blue)
                    }
                }

                if viewer.isAdminAllowed(.memberPermissionUpdate) {
                    NavigationLink {
                        RoleTemplateView(groupId: groupId)
                    } label: {
                        Label("Group Permissions", systemImage: "lock")
                            .labelStyle(SettingLabelStyle())
                            .tint(.teal)
                    }
                }
            } header: {
                #if os(iOS)
                header
                #endif
            }
            .headerProminence(.increased)

            Section {
                ForEach(members.value) { item in
                    MemberItemView(groupId: groupId, user: item.user)
                }
            } header: {
                Text("\(members.value.count) Members")
            }
            .headerProminence(.increased)

            #if os(iOS)
            Section {
                HStack {
                    Text("Group ID")
                    Spacer()
                    Text("\(groupId)")
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .lineLimit(1)
                }

                newEpochButton

                leaveButton
            }
            #endif
        }
        .busyOverlay(isPresented: $isLeavingGroup, busyText: "Leaving Group…")
        .sheet(isPresented: $isEditVisible) {
            if let group = group.value {
                GroupEditView(group: group)
            }
        }
        .navigationTitle(GroupModel.renderName(group.value))
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            #if os(iOS)
            if viewer.isAdminAllowed(.metadataUpdate) {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Edit") {
                        isEditVisible = true
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                if let group = group.value {
                    GroupTitleButton(group: group)
                        .opacity(isTitleViewVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 0.15), value: isTitleViewVisible)
                }
            }
            #endif

            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder var header: some View {
        let groupImageSize: CGFloat = platformValue(iOS: 170, macOS: 140)

        HStack {
            Spacer()

            VStack(alignment: .center, spacing: 0) {
                #if os(macOS)
                Spacer().frame(height: 16)
                #endif

                GroupImageView(group.value)
                    .frame(width: groupImageSize, height: groupImageSize)

                Spacer().frame(height: 16)

                Text(GroupModel.renderName(group.value))
                    .font(.title)
                    .fontWeight(.semibold)

                Spacer().frame(height: 32)
            }
            .frame(maxWidth: 400)

            Spacer()
        }
        .onAppear {
            isTitleViewVisible = false
        }
        .onDisappear {
            isTitleViewVisible = true
        }
    }

    @ViewBuilder var newEpochButton: some View {
        #if DEBUG
        Button {
            Task {
                do {
                    try await DataStore.shared.write { db in
                        try EpochDirtyModel.set(db, id: groupId, dirtyTimestamp: .now())
                    }

                    try await EpochCreateUseCase().run()
                } catch {
                    log(error)
                }
            }
        } label: {
            Text("New Epoch")
        }
        #endif
    }

    @ViewBuilder var leaveButton: some View {
        Button(role: .destructive) {
            isLeaveConfirmationVisible = true
        } label: {
            #if os(iOS)
            Text("Leave Group")
            #else
            Text("Leave")
            #endif
        }
        .confirmationDialog("Leave Group?", isPresented: $isLeaveConfirmationVisible) {
            Button("Leave Group", role: .destructive) {
                isLeavingGroup = true

                MemberLeaveUseCase(groupId: groupId, dataStore: dataStore)
                    .detachedTask {
                        success in
                        isLeavingGroup = false

                        if success {
                            dismiss()
                            navigationState.clear()
                        }
                    }
            }
        } message: {
            Text("Are you sure you want to leave “\(GroupModel.renderName(group.value))”?")
        }
    }
}

#Preview {
    let dataStore = DataStore.preview()
    return NavigationStack {
        GroupDetailView(groupId: Array(dataStore.previewGroupIdToThreadIds.keys)[0])
    }
    .environment(dataStore)
}

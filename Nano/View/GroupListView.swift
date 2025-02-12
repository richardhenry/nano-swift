//
//  GroupListView.swift
//  Nano
//
//  Created by Richard Henry on 1/28/24.
//

import NanoKit
import SwiftUI

struct GroupListView: View {
    @ViewModel private var groups = GroupListViewModel()
    @State private var isGroupCreateVisible = false
    @State private var isInviteAcceptVisible = false
    @State private var isSettingsVisible = false
    @Environment(NavigationState.self) private var navigationState

    var body: some View {
        @Bindable var navigationState = navigationState

        Group {
            if !groups.value.isEmpty {
                List(selection: $navigationState.groupId) {
                    ForEach(groups.value) { group in
                        GroupItemView(group: group)
                            .disabled(group.isPending)
                            .selectionDisabled(group.isPending)
                    }
                }
            } else {
                EmptyTextView("No Groups")
            }
        }
        .focusedValue(\.selectedGroup, $navigationState.groupId)
        .navigationTitle("Nano")
        .toolbarTitleDisplayMode(.inline)
        #if os(iOS)
        .searchable(text: $groups.searchText)
        #elseif os(macOS)
        .navigationSplitViewColumnWidth(min: 193, ideal: 193)
        .onChange(of: navigationState.searchText) { _, newValue in
            $groups.searchText.wrappedValue = newValue
        }
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isSettingsVisible = true
                } label: {
                    Label("Settings", systemImage: "person.crop.circle")
                        .labelStyle(.iconOnly)
                }
            }
            #endif

            ToolbarItem(placement: .primaryAction) {
                Menu("Add Group", systemImage: "plus") {
                    Button("Create Group") {
                        isGroupCreateVisible = true
                    }

                    Button("Join Group") {
                        isInviteAcceptVisible = true
                    }
                }
                .help("Create or join a group")
            }
        }
        .sheet(isPresented: $isGroupCreateVisible) {
            GroupCreateView()
        }
        .sheet(isPresented: $isInviteAcceptVisible) {
            InviteAcceptView()
        }
        .sheet(isPresented: $isSettingsVisible) {
            NavigationStack {
                SettingsView()
            }
        }
    }
}

//
//  InviteListView.swift
//  Nano
//
//  Created by Richard Henry on 1/17/24.
//

import NanoKit
import SwiftUI

struct InviteListView: View {
    let groupId: GroupID
    @ViewModel private var invites: InviteListViewModel
    @State private var isCreateVisible = false
    @Environment(\.dismiss) private var dismiss

    init(groupId: GroupID) {
        self.groupId = groupId
        _invites = InviteListViewModel(groupId: groupId).wrapped()
    }

    var body: some View {
        Form {
            Button {
                isCreateVisible = true
            } label: {
                #if os(macOS)
                Text("New")
                #else
                Label("New", systemImage: "plus")
                #endif
            }

            ForEach(invites.value) { invite in
                Text(
                    (try? InviteLinkUseCase().urlString(from: invite))
                        ?? "(not available on this device)"
                )
                .textSelection(.enabled)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Invite Links")
        .sheet(isPresented: $isCreateVisible) {
            InviteCreateView(groupId: groupId)
        }
    }
}

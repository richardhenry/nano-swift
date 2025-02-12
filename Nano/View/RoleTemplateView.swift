//
//  RoleTemplateView.swift
//  Nano
//
//  Created by Richard Henry on 2/4/24.
//

import NanoKit
import SwiftUI

struct RoleTemplateView: View {
    @ViewModel private var viewer: ViewerRoleViewModel
    @ViewModel private var model: RoleTemplateViewModel
    @ViewModel private var applyAllForm: RoleTemplateApplyViewModel
    @State private var isApplyAllPossible = true

    @MainActor var isApplyAllDisabled: Bool {
        !isApplyAllPossible || applyAllForm.formPhase.isDisabled || model.loadingPhase != .ready
            || !viewer.isAdminAllowed(.memberPermissionUpdate)
    }

    init(groupId: GroupID) {
        _viewer = ViewerRoleViewModel(groupId: groupId).wrapped()
        _model = RoleTemplateViewModel(groupId: groupId).wrapped()
        _applyAllForm = RoleTemplateApplyViewModel(groupId: groupId).wrapped()
    }

    var body: some View {
        Form {
            FormSection("Member Permissions", helpText: "The default permissions for new members.")
            {
                Toggle(isOn: $model.inviteCreate) {
                    Text("Invite others to the group")
                }

                Toggle(isOn: $model.messageCreate) {
                    Text("Send messages in the group")
                }

                if model.messageCreate {
                    Toggle(isOn: $model.threadCreate) {
                        Text("Create new threads")
                    }
                }
            }
            .disabled(
                model.loadingPhase != .ready || !viewer.isAdminAllowed(.memberPermissionUpdate)
            )

            #if os(macOS)
            Section("Apply All") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button {
                            isApplyAllPossible = false
                            applyAllForm.submit()
                        } label: {
                            Text("Apply to All Members")
                        }

                        LoadingView(applyAllForm)
                    }

                    Text("Apply these permissions to the existing members in the group.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(isApplyAllDisabled)
            #else
            Section {
                Button(role: .destructive) {
                    isApplyAllPossible = true
                    applyAllForm.submit()
                } label: {
                    HStack {
                        Text("Apply to All Members")
                        Spacer()
                        LoadingView(applyAllForm)
                    }
                }
            } footer: {
                Text("Apply these permissions to the existing members in the group.")
            }
            .disabled(isApplyAllDisabled)
            .animation(
                .easeInOut(duration: 0.15),
                value: isApplyAllDisabled
            )
            #endif
        }
        .toolbar {
            LoadingView(model)
        }
        .onChange(of: applyAllForm.formPhase) { _, newValue in
            if newValue.isError { isApplyAllPossible = true }
        }
        .onChange(of: model.inviteCreate) { _, _ in
            isApplyAllPossible = true
        }
        .onChange(of: model.threadCreate) { _, _ in
            isApplyAllPossible = true
        }
        .onChange(of: model.messageCreate) { _, _ in
            isApplyAllPossible = true
        }
        .formStyle(.grouped)
        .navigationTitle("Group Permissions")
    }
}

//
//  MemberDetailView.swift
//  Nano
//
//  Created by Richard Henry on 2/1/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct MemberDetailView: View {
    let groupId: GroupID
    let userId: UserID
    @ViewModel private var session: SessionViewModel
    @ViewModel private var viewer: ViewerRoleViewModel
    @ViewModel private var role: RoleViewModel
    @ViewModel private var member: MemberViewModel
    @ViewModel private var user: UserViewModel
    @ViewModel private var kickForm: MemberDeleteViewModel
    @State private var isTitleViewVisible = false
    @State private var isKicking = false
    @State private var isKickConfirmationVisible = false
    @Environment(\.dismiss) private var dismiss

    var isViewerDetail: Bool {
        session.value?.userId == userId
    }

    var canEditAdminPermissions: Bool {
        viewer.roleType == .owner
    }

    var canEditMemberPermissions: Bool {
        viewer.isAdminAllowed(.memberPermissionUpdate)
    }

    var canKick: Bool {
        (viewer.isAdminAllowed(.memberBanAndEpochCreate)
            && role.loadingPhase == .ready
            && role.roleType == .member)
            || (viewer.roleType == .owner && !isViewerDetail)
    }

    init(groupId: GroupID, userId: UserID) {
        self.groupId = groupId
        self.userId = userId
        _session = SessionViewModel().wrapped()
        _role = RoleViewModel(groupId: groupId, userId: userId).wrapped()
        _member = MemberViewModel(groupId: groupId, userId: userId).wrapped()
        _user = UserViewModel(userId: userId).wrapped()
        _viewer = ViewerRoleViewModel(groupId: groupId).wrapped()
        _kickForm = MemberDeleteViewModel(groupId: groupId, userId: userId).wrapped()
    }

    var body: some View {
        @Bindable var role = role

        if let member = member.value, let user = user.value {
            Form {
                #if os(macOS)
                Section {
                    header
                }
                #endif

                Section {
                    HStack {
                        Text("Joined Group")
                        Spacer()
                        DateTimeText(member.timestamp)
                            .foregroundStyle(.secondary)
                    }

                    if role.roleType != .owner {
                        HStack {
                            Text("Invited By")
                            Spacer()
                            if role.loadingPhase != .ready {
                                LoadingView(role)
                            } else {
                                UserNameText(user: role.invitedByUser)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if role.loadingPhase != .ready || role.roleType == .owner
                        || !canEditAdminPermissions
                    {
                        HStack {
                            Text("Group Role")
                            Spacer()
                            if role.loadingPhase != .ready {
                                LoadingView(role)
                            } else {
                                role.roleType.localizedText
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Picker("Group Role", selection: $role.roleType) {
                            ForEach(RoleType.formCases) {
                                $0.localizedText
                            }
                        }
                    }

                    HStack {
                        Text("User ID")
                        Spacer()
                        Text("\(userId)")
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .lineLimit(1)
                    }
                } header: {
                    #if os(iOS)
                    header
                    #endif
                }
                .headerProminence(.increased)
                .animation(.none, value: role.loadingPhase)
                .animation(.none, value: role.roleType)

                if canEditMemberPermissions, role.loadingPhase == .ready {
                    if role.roleType.hasAdminPermissions {
                        FormSection("Admin Permissions", helpText: adminHelpText) {
                            Toggle(isOn: $role.memberPermissionUpdate) {
                                Text("Edit member permissions")
                            }

                            Toggle(isOn: $role.metadataUpdate) {
                                Text("Edit the group details")
                            }

                            Toggle(isOn: $role.messageDelete) {
                                Text("Delete messages in the group")
                            }

                            Toggle(isOn: $role.memberBan) {
                                Text("Kick members from the group")
                            }
                        }
                        .disabled(role.roleType == .owner || !canEditAdminPermissions)
                    }

                    Section("Member Permissions") {
                        Toggle(isOn: $role.inviteCreate) {
                            Text("Invite others to the group")
                        }

                        Toggle(isOn: $role.messageCreate) {
                            Text("Send messages in the group")
                        }

                        if role.messageCreate {
                            Toggle(isOn: $role.threadCreate) {
                                Text("Create new threads")
                            }
                        }
                    }
                    .disabled(role.roleType.hasAdminPermissions)
                }

                if canKick, role.loadingPhase == .ready {
                    Section {
                        Button(role: .destructive) {
                            isKickConfirmationVisible = true
                        } label: {
                            Text("Kick Member")
                        }
                        .confirmationDialog(
                            "Kick Member?",
                            isPresented: $isKickConfirmationVisible
                        ) {
                            Button("Kick Member", role: .destructive) {
                                kickForm.submit()
                            }
                        } message: {
                            Text(
                                "Are you sure you want to kick “\(UserModel.renderName(user))”? They will be banned from the group."
                            )
                        }
                    } header: {
                        #if os(macOS)
                        Text("Remove from Group")
                        #endif
                    }
                }
            }
            .formStyle(.grouped)
            .busyOverlay(isPresented: $isKicking, busyText: "Kicking…")
            .navigationTitle(user.name)
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    UserTitleButton(user: user)
                    .opacity(isTitleViewVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.15), value: isTitleViewVisible)
                }
            }
            .animation(.default, value: role.loadingPhase)
            .animation(.default, value: role.roleType)
            #endif
        } else {
            EmptyTextView("Not Found", isObservingSearch: false)
                .navigationTitle("Member")
        }
    }

    var adminHelpText: LocalizedStringKey? {
        guard !isViewerDetail else {
            return nil
        }

        if viewer.value?.roleType == .owner {
            return "Only you can edit admin permissions or make someone an admin."
        } else {
            return "Only the owner can edit admin permissions or make someone an admin."
        }
    }

    @ViewBuilder var header: some View {
        let userImageSize: CGFloat = platformValue(iOS: 170, macOS: 140)

        HStack {
            Spacer()

            VStack(alignment: .center, spacing: 0) {
                #if os(macOS)
                Spacer().frame(height: 16)
                #endif

                UserImageView(user.value, size: .medium)
                    .frame(width: userImageSize, height: userImageSize)

                Spacer().frame(height: 16)

                Text(UserModel.renderName(user.value))
                    .font(.title)
                    .fontWeight(.semibold)

                Spacer().frame(height: platformValue(iOS: 32, macOS: 16))
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
}

extension RoleType: Identifiable {
    public var id: Self { self }

    static var formCases: [RoleType] {
        [.member, .admin]
    }

    var localizedText: Text {
        switch self {
        case .owner:
            Text("Owner")
        case .admin:
            Text("Admin")
        case .member:
            Text("Member")
        }
    }
}

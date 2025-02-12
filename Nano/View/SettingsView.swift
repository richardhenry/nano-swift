//
//  SettingsView.swift
//  Nano
//
//  Created by Richard Henry on 4/19/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct SettingsView: View {
    @ViewModel private var user = SessionUserViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @State private var isTitleViewVisible = false
    @State private var isEditVisible = false
    @State private var isSendFeedbackVisible = false
    @State private var isSignOutConfirmationVisible = false

    var body: some View {
        List {
            Section {
                #if os(macOS)
                ZStack(alignment: .topTrailing) {
                    HStack {
                        Button("Edit") {
                            isEditVisible = true
                        }
                    }

                    header
                }
                .listRowSeparator(.hidden)
                #endif

                NavigationLink {
                    RecoveryKeyView()
                } label: {
                    Label("Recovery Key", systemImage: "key")
                        .labelStyle(SettingLabelStyle())
                        .tint(.yellow)
                }
            } header: {
                #if os(iOS)
                header
                #endif
            }
            .headerProminence(.increased)

            Section {
                Button {
                    isSendFeedbackVisible = true
                } label: {
                    Label("Send Feedback", systemImage: "ladybug")
                        .labelStyle(SettingLabelStyle())
                }
            }

            Section {
                Button("Sign Out", role: .destructive) {
                    isSignOutConfirmationVisible = true
                }
            }
        }
        .sheet(isPresented: $isEditVisible) {
            if let value = user.value {
                UserEditView(user: value)
            }
        }
        .sheet(isPresented: $isSendFeedbackVisible) {
            SendFeedbackView()
        }
        .confirmationDialog("Sign Out?", isPresented: $isSignOutConfirmationVisible) {
            Button("Sign Out", role: .destructive) {
                SignOutUseCase().detachedTask()
            }
        } message: {
            Text(
                "Save your Recovery Key before signing out to make sure that you can sign back into your account."
            )
        }
        .navigationTitle(UserModel.renderName(user.value))
        .toolbarTitleDisplayMode(.inline)
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Edit") {
                    isEditVisible = true
                }
            }

            ToolbarItem(placement: .principal) {
                if let user = user.value {
                    UserTitleButton(user: user, action: nil)
                    .opacity(isTitleViewVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.15), value: isTitleViewVisible)
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        #endif
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
}

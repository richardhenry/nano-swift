//
//  MessageView.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

import Foundation
import NanoCore
import NanoKit
import SwiftUI

struct MessageView: View {
    static let userImageSize: CGFloat = platformValue(iOS: 34, macOS: 28)
    static let horizontalSpacing: CGFloat = 12
    var message: MessageModel
    var user: UserModel?
    var header: Bool
    @State private var isReactionPickerVisible = false
    @State private var isEditVisible = false
    @State private var isRetryConfirmationVisible = false
    @State private var isDeleteConfirmationVisible = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if header {
                UserImageView(user, size: .small)
                    .frame(width: Self.userImageSize, height: Self.userImageSize)
                    .offset(y: 1)
            } else {
                Color.clear
                    .frame(width: Self.userImageSize)
            }

            Spacer().frame(width: Self.horizontalSpacing)

            VStack(alignment: .leading, spacing: 8) {
                if header {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        UserNameText(user: user)
                            .fontWeight(.semibold)
                        TimeText(message.createTimestamp)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if message.isEmpty {
                    Text("This message is not available.")
                        .foregroundStyle(.secondary)
                }

                if let text = message.text {
                    Text(text)
                        .textSelection(.enabled)
                }

                if let links = message.links {
                    ForEach(links) {
                        LinkPreviewButton(preview: $0)
                    }
                }

                if let attachments = message.attachments {
                    AttachmentGridView(attachments: attachments)
                }

                if message.sendState == .failed {
                    Button {
                        isRetryConfirmationVisible = true
                    } label: {
                        Label("Send Failed", systemImage: "exclamationmark.circle.fill")
                            .labelSpacing(3)
                    }
                    .buttonStyle(.borderless)
                    .font(platformValue(iOS: .subheadline, macOS: .body))
                    .fontWeight(.bold)
                    .tint(.red)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .contextMenu {
            MessageContextMenu(
                message: message,
                isReactionPickerVisible: $isReactionPickerVisible,
                isEditVisible: $isEditVisible,
                isDeleteConfirmationVisible: $isDeleteConfirmationVisible
            )
        }
        .sheet(isPresented: $isReactionPickerVisible) {
            ReactionPickerView(groupId: message.groupId, targetId: message.id)
        }
        .sheet(isPresented: $isEditVisible) {
            EditMessageView(existingMessage: message)
        }
        .confirmationDialog("Message Send Failed", isPresented: $isRetryConfirmationVisible) {
            Button("Try Again") {
                MessageSendRetryUseCase(groupId: message.groupId, messageId: message.id)
                    .detachedTask()
            }
            .keyboardShortcut(.defaultAction)
        } message: {
            Text("Your message was not sent. Would you like to try again?")
        }
        .confirmationDialog("Delete Message?", isPresented: $isDeleteConfirmationVisible) {
            Button("Delete Message", role: .destructive) {
                MessageDeleteUseCase(message: message).detachedTask()
            }
        } message: {
            Text("Are you sure you want to delete this message?")
        }
    }
}

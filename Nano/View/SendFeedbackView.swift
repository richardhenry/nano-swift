//
//  SendFeedbackView.swift
//  Nano
//
//  Created by Richard Henry on 4/19/24.
//

import Flow
import NanoKit
import SwiftUI

struct SendFeedbackView: View {
    @ViewModel private var session = SessionViewModel()
    @ViewModel private var feedback = SendFeedbackViewModel()
    @State private var isPhotoPickerVisible = false
    @State private var isFilePickerVisible = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                FormSection("Your Feedback") {
                    TextEditor(text: $feedback.text)
                        .frame(minHeight: 80)
                }

                FormSection(
                    "Attachments",
                    helpText:
                        "So that we can debug the problem, your feedback will include internal event logs. These logs may contain metadata about messages sent and received, but the content of your messages will never be included. Please attach anything else that you think may be helpful."
                ) {
                    if !feedback.attachmentPicker.isEmpty {
                        HFlow(spacing: 5) {
                            ForEach(feedback.attachmentPicker.attachments) { item in
                                ComposeAttachmentView(attachment: item) {
                                    feedback.attachmentPicker.remove(item)
                                }
                            }
                        }
                    }

                    Button {
                        isPhotoPickerVisible = true
                    } label: {
                        Label("Add Photo or Video", systemImage: "photo.on.rectangle.angled")
                    }

                    Button {
                        isFilePickerVisible = true
                    } label: {
                        Label("Add File", systemImage: "doc")
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Send Feedback")
            .toolbarTitleDisplayMode(.inline)
            .form(
                feedback,
                onCompletion: {
                    dismiss()
                }
            )
            .formToolbar(
                for: feedback,
                submitText: "Send",
                onCancel: {
                    dismiss()
                }
            )
            .attachmentPicker(
                feedback.attachmentPicker,
                isCameraVisible: .constant(false),
                isPhotoPickerVisible: $isPhotoPickerVisible,
                isFilePickerVisible: $isFilePickerVisible
            )
            .onChange(of: session.value?.userId, initial: true) { _, newValue in
                feedback.userId = newValue
            }
            .onChange(of: feedback.formPhase) { _, newValue in
                if newValue == .complete {
                    dismiss()
                }
            }
        }
        #if os(macOS)
        .frame(width: 360)
        .frame(minHeight: 512)
        #endif
    }
}

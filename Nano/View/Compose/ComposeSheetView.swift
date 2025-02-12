//
//  ComposeSheetView.swift
//  Nano
//
//  Created by Richard Henry on 4/17/24.
//

import NanoKit
import SwiftUI

struct ComposeSheetView: View {
    @Binding var isFocused: Bool
    @Bindable var compose: ComposeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {  // Accessory bottom inset doesn't work correctly with ScrollView.
            ComposeEditorView(isFocused: $isFocused, compose: compose)
                .padding(.horizontal)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
        .safeAreaPadding(.top)
        .keyboardAccessory {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(
                            width: MessageView.userImageSize,
                            height: MessageView.userImageSize
                        )
                }
                .accessibilityLabel("Cancel")
                .foregroundStyle(.secondary)

                Spacer()

                ComposeAttachmentMenu(compose: compose)
                ComposeSendButton(compose: compose)
            }
            .padding()
        }
        .attachmentPicker(compose: compose)
        .onChange(of: compose.formPhase) { _, newValue in
            if newValue == .complete {
                dismiss()
            }
        }
        .interactiveDismissDisabled()
    }
}

//
//  ComposeEditorView.swift
//  Nano
//
//  Created by Richard Henry on 4/16/24.
//

import Flow
import SwiftUI

#if os(iOS)
import Nano_iOS
#elseif os(macOS)
import Nano_Mac
#endif

struct ComposeEditorView: View {
    @Binding var isFocused: Bool
    @Bindable var compose: ComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MessageTextView(isFocused: $isFocused, delegate: compose)
                .frame(minWidth: 0, maxWidth: .infinity)

            if !compose.links.isEmpty {
                ForEach(compose.links) { provider in
                    LinkPreviewView(provider: provider)
                        .overlay(alignment: .topTrailing) {
                            Button {
                                compose.links.removeAll { $0.url == provider.url }
                                compose.textCoordinator?.insertText(provider.url.absoluteString)
                            } label: {
                                Label("Remove", systemImage: "xmark.circle.fill")
                                    .labelStyle(.iconOnly)
                            }
                            .foregroundStyle(.primary, .regularMaterial)
                            .environment(\.colorScheme, .dark)
                            .buttonStyle(.borderless)
                            .offset(x: -3, y: 3)
                        }
                }

                Spacer().frame(height: 8)
            }

            if !compose.attachmentPicker.isEmpty {
                HFlow(spacing: 5) {
                    ForEach(compose.attachmentPicker.attachments) { item in
                        ComposeAttachmentView(attachment: item) {
                            compose.attachmentPicker.remove(item)
                        }
                    }
                }

                Spacer().frame(height: 8)
            }
        }
    }
}

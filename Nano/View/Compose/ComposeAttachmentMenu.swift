//
//  ComposeAttachmentMenu.swift
//  Nano
//
//  Created by Richard Henry on 4/17/24.
//

import SwiftUI

struct ComposeAttachmentMenu: View {
    @Bindable var compose: ComposeViewModel

    var body: some View {
        Menu {
            #if os(iOS)
            Button("Open Camera", systemImage: "camera") {
                compose.isCameraVisible = true
            }
            #endif

            Button("Add Photo or Video", systemImage: "photo.on.rectangle.angled") {
                compose.isPhotoPickerVisible = true
            }

            Button("Add File", systemImage: "doc") {
                compose.isFilePickerVisible = true
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .frame(
                    width: MessageView.userImageSize,
                    height: MessageView.userImageSize
                )
        }
        .accessibilityLabel("Add Attachment")
        .menuOrder(.fixed)
        .foregroundStyle(.secondary)
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
    }
}

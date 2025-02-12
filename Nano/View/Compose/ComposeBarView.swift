//
//  ComposeBarView.swift
//  Nano
//
//  Created by Richard Henry on 1/3/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct ComposeBarView: View {
    let groupId: GroupID
    let threadId: ThreadID?
    @ViewModel private var viewer: ViewerRoleViewModel
    @ViewModel private var compose: ComposeViewModel
    @State private var isFocused = false
    @State private var currentEditorSize: CGSize = .zero
    @ScaledMetric private var initialBarHeight: CGFloat = platformValue(iOS: 48, macOS: 42)

    init(groupId: GroupID, threadId: ThreadID?) {
        self.groupId = groupId
        self.threadId = threadId
        _viewer = ViewerRoleViewModel(groupId: groupId).wrapped()
        _compose = ComposeViewModel(groupId: groupId, existingThreadId: threadId).wrapped()
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if viewer.isMemberAllowed(.messageCreate) {
                ComposeAttachmentMenu(compose: compose)
                    .frame(height: initialBarHeight)

                Spacer(minLength: MessageView.horizontalSpacing)

                ScrollView {
                    ComposeEditorView(isFocused: $isFocused, compose: compose)
                        .frame(minHeight: initialBarHeight)
                        .overlay {
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(key: ComposeEditingSize.self, value: geometry.size)
                            }
                        }
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    maxHeight: currentEditorSize.height
                )

                Spacer(minLength: 5)

                #if !os(macOS)
                ComposeSendButton(compose: compose)
                    .frame(height: initialBarHeight)
                #endif
            } else {
                Spacer()

                Text("You can’t send messages in this group.")
                    .foregroundStyle(.secondary)
                    .frame(height: initialBarHeight)

                Spacer()
            }
        }
        .padding(.horizontal)
        .background {
            RoundedRectangle(cornerRadius: platformValue(iOS: 12, macOS: 8), style: .continuous)
                .fill(.regularMaterial)
                .padding(.horizontal, 6)
        }
        .padding(.vertical, platformValue(iOS: 4, macOS: 6))
        .onPreferenceChange(ComposeEditingSize.self) { size in
            currentEditorSize = size
        }
        .attachmentPicker(compose: compose)
        .onChange(of: viewer.isMemberAllowed(.messageCreate)) { _, newValue in
            compose.isEnabled = newValue
        }
    }
}

struct ComposeEditingSize: PreferenceKey {
    static var defaultValue = CGSize.zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

#Preview {
    ComposeBarView(groupId: GroupID(), threadId: nil)
        .environment(DataStore.ephemeral())
}

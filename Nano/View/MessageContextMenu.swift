//
//  MessageContextMenu.swift
//  Nano
//
//  Created by Richard Henry on 2/25/24.
//

import NanoKit
import SwiftUI

struct MessageContextMenu: View {
    let message: MessageModel
    @Binding var isReactionPickerVisible: Bool
    @Binding var isEditVisible: Bool
    @Binding var isDeleteConfirmationVisible: Bool
    @Environment(\.displayScale) private var displayScale
    @ViewModel private var session = SessionViewModel()
    @ViewModel private var viewer: ViewerRoleViewModel
    @ViewModel private var reactionPalette: ReactionPaletteViewModel

    init(
        message: MessageModel,
        isReactionPickerVisible: Binding<Bool>,
        isEditVisible: Binding<Bool>,
        isDeleteConfirmationVisible: Binding<Bool>
    ) {
        self.message = message
        _isReactionPickerVisible = isReactionPickerVisible
        _isEditVisible = isEditVisible
        _isDeleteConfirmationVisible = isDeleteConfirmationVisible

        _viewer = ViewerRoleViewModel(groupId: message.groupId).wrapped()

        _reactionPalette = ReactionPaletteViewModel(
            groupId: message.groupId,
            targetId: message.id
        )
        .wrapped()
    }

    var body: some View {
        ControlGroup {
            ForEach(reactionPalette.value) { reaction in
                Button {
                    ReactionToggleUseCase(
                        groupId: message.groupId,
                        targetId: message.id,
                        base: reaction.base,
                        variation: reaction.variation
                    )
                    .detachedTask()
                } label: {
                    let content = Text(reaction.display)
                        .opacity(reaction.isSelected ? 0.4 : 1)

                    if let image = content.renderImage(scale: displayScale) {
                        Image(platformImage: image)
                    }
                }
                .accessibilityLabel(reaction.display)
                .menuActionDismissBehavior(.enabled)
            }
        }
        .controlGroupStyle(.palette)

        Button("Add Reaction…", systemImage: "face.smiling") {
            isReactionPickerVisible = true
        }

        #if os(iOS)
        if message.text?.isEmpty == false {
            Button("Copy Text", systemImage: "doc.on.doc") {
                UIPasteboard.general.string = message.renderPlaintext()
            }
        }
        #endif

        if message.userId == session.value?.userId, viewer.isMemberAllowed(.messageCreate) {
            Button("Edit", systemImage: "pencil") {
                isEditVisible = true
            }
        }

        if message.userId == session.value?.userId || viewer.isAdminAllowed(.messageDelete) {
            Button("Delete", systemImage: "trash", role: .destructive) {
                isDeleteConfirmationVisible = true
            }
        }
    }
}

//
//  ReactionPickerView.swift
//  Nano
//
//  Created by Richard Henry on 2/25/24.
//

import NanoKit
import SwiftUI

struct ReactionPickerView: View {
    let groupId: GroupID
    let targetId: MessageID
    @ViewModel private var reactions: ReactionSelectedViewModel
    @ViewModel private var defaultSkinToneVariation = EmojiSkinToneViewModel()

    var selected: Set<String> {
        Set(reactions.value.compactMap { $0.base })
    }

    init(groupId: GroupID, targetId: MessageID) {
        self.groupId = groupId
        self.targetId = targetId
        _reactions = ReactionSelectedViewModel(groupId: groupId, targetId: targetId).wrapped()
    }

    var body: some View {
        NavigationStack {
            EmojiPickerView(selected: selected, skinToneVariation: defaultSkinToneVariation.value) {
                selection in
                ReactionToggleUseCase(
                    groupId: groupId,
                    targetId: targetId,
                    base: selection.base,
                    variation: selection.variation
                )
                .detachedTask()
            } skinToneVariationModified: { skinToneVariation in
                ReactionSetDefaultSkinToneUseCase(skinToneVariation: skinToneVariation)
                    .detachedTask()
            }
            .navigationTitle("Add Reaction")
        }
        .presentationDetents([.medium, .large])
        #if os(macOS)
        .frame(width: 326, height: 360)
        #endif
    }
}

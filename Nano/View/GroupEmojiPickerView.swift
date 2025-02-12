//
//  GroupEmojiPickerView.swift
//  Nano
//
//  Created by Richard Henry on 5/28/24.
//

import NanoKit
import SwiftUI

struct GroupEmojiPickerView<Model: GroupEditFormViewModel>: View {
    var form: Model
    @ViewModel private var defaultSkinToneVariation = EmojiSkinToneViewModel()

    var selected: Set<String> {
        if let emoji = form.emoji {
            Set([emoji])
        } else {
            Set()
        }
    }

    var body: some View {
        NavigationStack {
            EmojiPickerView(selected: selected, skinToneVariation: defaultSkinToneVariation.value) {
                form.emoji = $0.variation ?? $0.base
            } skinToneVariationModified: { _ in
            }
            .navigationTitle("Choose Emoji")
        }
        .presentationDetents([.medium, .large])
        #if os(macOS)
        .frame(width: 326, height: 360)
        #endif
    }
}

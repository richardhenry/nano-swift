//
//  EmojiPickerView.swift
//  Nano
//
//  Created by Richard Henry on 2/21/24.
//

import NanoKit
import SwiftUI

struct EmojiPickerView: View {
    struct Selection {
        var base: String
        var variation: String?
    }

    var selected = Set<String>()
    var isDeselectEnabled = true
    var skinToneVariation: Int?
    var selection: (Selection) -> Void
    var skinToneVariationModified: ((Int?) -> Void)?
    @State private var model = EmojiPickerViewModel()
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 44, maximum: 44), spacing: 0)],
                spacing: 0
            ) {
                ForEach(Emoji.Category.allCases) { category in
                    if let items = model.map[category] {
                        Section {
                            ForEach(items) { emoji in
                                let isSelected = selected.contains(emoji.value)

                                Button {
                                    selection(
                                        Selection(
                                            base: emoji.value,
                                            variation: skinToneVariation != nil
                                                ? emoji.skinToneVariations[
                                                    ifExists: skinToneVariation!
                                                ] : nil
                                        )
                                    )
                                    dismiss()
                                } label: {
                                    ZStack {
                                        Color.clear

                                        Text(emoji.render(skinToneVariation: skinToneVariation))
                                            .font(.title)
                                    }
                                }
                                .contextMenu {
                                    ControlGroup {
                                        Button {
                                            selection(Selection(base: emoji.value))
                                            if !emoji.skinToneVariations.isEmpty {
                                                skinToneVariationModified?(nil)
                                            }
                                            dismiss()
                                        } label: {
                                            if let image = Text(emoji.value)
                                                .renderImage(
                                                    scale: displayScale
                                                )
                                            {
                                                Image(platformImage: image)
                                            }
                                        }
                                        .menuActionDismissBehavior(.enabled)

                                        ForEach(emoji.skinToneVariations) { variation in
                                            Button {
                                                selection(
                                                    Selection(
                                                        base: emoji.value,
                                                        variation: variation
                                                    )
                                                )
                                                skinToneVariationModified?(
                                                    emoji.skinToneVariations.firstIndex(
                                                        of: variation
                                                    )
                                                )
                                                dismiss()
                                            } label: {
                                                if let image = Text(variation)
                                                    .renderImage(
                                                        scale: displayScale
                                                    )
                                                {
                                                    Image(platformImage: image)
                                                }
                                            }
                                            .menuActionDismissBehavior(.enabled)
                                        }
                                    }
                                    .controlGroupStyle(.palette)
                                } preview: {
                                    ZStack {
                                        Rectangle()
                                            .fill(.background)

                                        Text(emoji.render(skinToneVariation: skinToneVariation))
                                            .font(.largeTitle)
                                    }
                                    .frame(width: 60, height: 60)
                                }
                                .opacity(isSelected ? 0.4 : 1)
                                .disabled(isSelected && !isDeselectEnabled)
                                .frame(width: 44, height: 44)
                                .buttonStyle(.borderless)
                            }
                        } header: {
                            Text(category.localizedName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        #if os(iOS)
        .searchable(
            text: Bindable(model).query,
            placement: .navigationBarDrawer(displayMode: .always)
        )
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
        }
    }
}

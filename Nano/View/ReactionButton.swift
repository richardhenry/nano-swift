//
//  ReactionButton.swift
//  Nano
//
//  Created by Richard Henry on 2/22/24.
//

import NanoKit
import SwiftUI

struct ReactionButton: View {
    var groupId: GroupID
    var targetId: MessageID
    var reaction: ReactionAggregatedQuery.Item
    @Binding var isReactionListVisible: Bool
    @State private var isHighlighted = false

    var body: some View {
        let style = ReactionButtonStyle(
            isHighlighted: $isHighlighted,
            isSelected: reaction.includesViewer
        ) {
            isReactionListVisible = true
        }

        Button {
            ReactionToggleUseCase(
                groupId: groupId,
                targetId: targetId,
                base: reaction.base,
                variation: nil
            )
            .detachedTask()
        } label: {
            HStack(spacing: 2) {
                ForEach(reaction.variations) {
                    Text($0)
                }

                Text(reaction.count.formatted())
                    .monospacedDigit()
                    .font(.subheadline)
            }
            .opacity(isHighlighted ? 0.4 : 1)
            .animation(!isHighlighted ? .easeOut : .easeIn(duration: 0), value: isHighlighted)
            .padding(EdgeInsets(top: 5, leading: 6, bottom: 5, trailing: 8))
        }
        .buttonStyle(style)
    }
}

struct ReactionButtonStyle: PrimitiveButtonStyle {
    @Binding var isHighlighted: Bool
    var isSelected: Bool
    let longPressAction: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? .white : .primary)
            .background {
                Capsule(style: .continuous)
                    .fill(isSelected ? .accent : .accent.opacity(0.3))
            }
            .onTapGesture {
                configuration.trigger()
            }
            .onLongPressGesture {
                longPressAction()
            } onPressingChanged: { isPressed in
                isHighlighted = isPressed
            }
    }
}

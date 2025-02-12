//
//  ReactionStackView.swift
//  Nano
//
//  Created by Richard Henry on 2/21/24.
//

import Flow
import NanoKit
import SwiftUI

struct ReactionStackView: View {
    let groupId: GroupID
    let targetId: MessageID
    var reactions: [ReactionAggregatedQuery.Item]
    @State private var isReactionListVisible = false

    var body: some View {
        HFlow(spacing: 5) {
            ForEach(reactions) { reaction in
                ReactionButton(
                    groupId: groupId,
                    targetId: targetId,
                    reaction: reaction,
                    isReactionListVisible: $isReactionListVisible
                )
            }
        }
        .padding(.vertical, 5)
        .sheet(isPresented: $isReactionListVisible) {
            NavigationStack {
                ReactionListView(groupId: groupId, targetId: targetId)
            }
            .presentationDetents([.medium, .large])
        }
    }
}

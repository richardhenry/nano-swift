//
//  ReactionListView.swift
//  Nano
//
//  Created by Richard Henry on 2/22/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct ReactionListView: View {
    @ViewModel private var reactions: ReactionListViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale

    init(groupId: GroupID, targetId: MessageID) {
        _reactions = ReactionListViewModel(groupId: groupId, targetId: targetId).wrapped()
    }

    var body: some View {
        List {
            ForEach(reactions.sections) { section in
                Section {
                    ForEach(reactions.items(in: section)) { item in
                        HStack(alignment: .center, spacing: 8) {
                            let userImageSize: CGFloat = platformValue(iOS: 28, macOS: 24)
                            UserImageView(item.user, size: .small)
                                .frame(width: userImageSize, height: userImageSize)

                            Text(UserModel.renderName(item.user))

                            Spacer()

                            if let display = item.reaction.display {
                                Text(display)
                                    .font(.title2)
                                    .frame(height: userImageSize)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Reactions")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

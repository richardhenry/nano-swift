//
//  GroupTitleButton.swift
//  Nano
//
//  Created by Richard Henry on 2/3/24.
//

import NanoKit
import SwiftUI

struct GroupTitleButton: View {
    var group: GroupModel
    var action: (() -> Void)?
    var imageSize: CGFloat = 28

    var body: some View {
        if let action = action {
            Button(action: action) { content }.tint(.primary)
        } else {
            content
        }
    }

    @ViewBuilder var content: some View {
        HStack(spacing: 6) {
            GroupImageView(group)
                .frame(
                    idealWidth: imageSize,
                    maxWidth: imageSize,
                    idealHeight: imageSize,
                    maxHeight: imageSize
                )

            Text(GroupModel.renderName(group))
                .fontWeight(.semibold)

            if action != nil {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 13))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary, Color.secondary.opacity(0.3))
            }
        }
    }
}

#Preview {
    let dataStore = DataStore.preview()
    let group = try! dataStore.read { db in
        try GroupModel.fetchExpect(db, id: Array(dataStore.previewGroupIdToThreadIds.keys)[0])
    }
    return VStack(spacing: 30) {
        GroupTitleButton(group: group) {}
        GroupTitleButton(group: group, action: nil)
    }
}

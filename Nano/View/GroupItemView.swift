//
//  GroupItemView.swift
//  Nano
//
//  Created by Richard Henry on 3/14/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct GroupItemView: View {
    var group: GroupModel
    @Environment(\.prefersSplitView) private var prefersSplitView

    var body: some View {
        if prefersSplitView {
            NavigationLink(value: group.id) {
                content
            }
        } else {
            NavigationLink {
                GroupContentView(groupId: group.id)
            } label: {
                content
            }
        }
    }

    @ViewBuilder var content: some View {
        HStack(alignment: .center, spacing: 8) {
            #if os(iOS)
            unreadBadge
            #endif
            groupImage
            Text(group.name)
            #if os(macOS)
            Spacer()
            unreadBadge
            #endif
        }
    }

    @ViewBuilder var unreadBadge: some View {
        let badgeSize: CGFloat = platformValue(iOS: 11, macOS: 9)

        if group.isPending {
            ProgressView()
                .controlSize(.small)
                .frame(width: badgeSize, height: badgeSize)
        } else {
            Circle()
                .fill(group.isUnread ? .accent : .clear)
                .frame(width: badgeSize, height: badgeSize)
        }
    }

    @ViewBuilder var groupImage: some View {
        let groupImageSize: CGFloat = platformValue(iOS: 28, macOS: 24)

        GroupImageView(group)
            .frame(width: groupImageSize, height: groupImageSize)
    }
}

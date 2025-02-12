//
//  ThreadRowView.swift
//  Nano
//
//  Created by Richard Henry on 1/25/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct ThreadItemView: View {
    var thread: ThreadModel
    var visibility: ThreadVisibilityValue
    var message: MessageModel?
    var user: UserModel?
    @Environment(\.prefersSplitView) private var prefersSplitView

    var body: some View {
        Group {
            if prefersSplitView {
                NavigationLink(value: thread.id) {
                    content
                }
            } else {
                NavigationLink {
                    ThreadContentView(groupId: thread.groupId, threadId: thread.id)
                } label: {
                    content
                }
            }
        }
        .contextMenu {
            Group {
                starButton
                archiveButton
            }
        }
        .swipeActions(edge: .leading) {
            starButton
                .symbolVariant(.fill)
                .tint(visibility == .starred ? .gray : .orange)
        }
        .swipeActions(edge: .trailing) {
            archiveButton
                .symbolVariant(.fill)
                .tint(.brown)
        }
    }

    @ViewBuilder var content: some View {
        HStack(alignment: .top, spacing: 8) {
            badgeStack

            VStack(alignment: .leading, spacing: 2) {
                Text(ThreadModel.renderSubject(thread))
                    .font(.headline)
                    .lineLimit(1)

                if let message = message {
                    MessageText(message: message, user: user)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    Text("Nothing yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    TimeText(thread.badgeTimestamp)

                    Text("\(thread.totalCount.formatted())")

                    if thread.unreadCount > 0 {
                        Text("(\(thread.unreadCount.formatted()) New)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder var badgeStack: some View {
        let starSize: CGFloat = platformValue(iOS: 15, macOS: 13)
        let unreadSize: CGFloat = platformValue(iOS: 12, macOS: 11)

        VStack(spacing: 0) {
            if visibility == .starred {
                Spacer().frame(height: 2)

                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.orange)
                    .frame(width: starSize, height: starSize)

                Spacer().frame(height: platformValue(iOS: 5, macOS: 6))
            } else {
                Spacer().frame(height: platformValue(iOS: 4, macOS: 3))
            }

            Circle()
                .fill(thread.isUnread ? .accent : .clear)
                .frame(width: unreadSize, height: unreadSize)
                .padding(.horizontal, starSize - unreadSize)
        }
    }

    @ViewBuilder var starButton: some View {
        Button {
            let thread = thread

            let value: ThreadVisibilityValue = visibility == .starred ? .default : .starred

            ThreadSettingUseCase(
                groupId: thread.groupId,
                threadId: thread.id,
                settingType: .visibility,
                value: value
            )
            .detachedTask()
        } label: {
            if visibility == .starred {
                Label("Unstar Thread", systemImage: "star.slash")
            } else {
                Label("Star Thread", systemImage: "star")
            }
        }
    }

    @ViewBuilder var archiveButton: some View {
        Button {
            let thread = thread

            let value: ThreadVisibilityValue = visibility == .archived ? .default : .archived

            ThreadSettingUseCase(
                groupId: thread.groupId,
                threadId: thread.id,
                settingType: .visibility,
                value: value
            )
            .detachedTask()
        } label: {
            if visibility == .archived {
                Label("Unarchive Thread", systemImage: "archivebox")
            } else {
                Label("Archive Thread", systemImage: "archivebox")
            }
        }
    }
}

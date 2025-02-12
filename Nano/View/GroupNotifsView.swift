//
//  GroupNotifsView.swift
//  Nano
//
//  Created by Richard Henry on 1/30/24.
//

import NanoKit
import SwiftUI

struct GroupNotifsView: View {
    @ViewModel private var model: GroupNotifsViewModel
    @Environment(\.dismiss) private var dismiss

    init(groupId: GroupID) {
        _model = GroupNotifsViewModel(groupId: groupId).wrapped()
    }

    var body: some View {
        Form {
            Section {
                Picker("Message Alerts", selection: $model.notifs) {
                    ForEach(GroupNotifsValue.formCases) {
                        $0.localizedText
                    }
                }
                #if os(iOS)
                .pickerStyle(.navigationLink)
                #endif

                Toggle(isOn: $model.starOnReply) {
                    Text("Star a thread automatically when I reply")
                }
            } header: {
                Text("Messages")
            } footer: {
                #if os(iOS)
                switch model.notifs {
                case .off:
                    Text("You will not receive any new message notifications in this group.")
                case .allMessages:
                    Text("You will receive a notification for every message in this group.")
                case .onlyStarredThreads:
                    Text("You will only receive notifications for messages in starred threads.")
                }
                #endif
            }

            Section("Activity") {
                Toggle(isOn: $model.mentionNotifs) {
                    Text("Notify me when someone mentions me")
                }

                Toggle(isOn: $model.replyNotifs) {
                    Text("Notify me for replies to my messages")
                }

                Toggle(isOn: $model.reactionNotifs) {
                    Text("Notify me for reactions on my messages")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Notifications")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

extension GroupNotifsValue: Identifiable {
    public var id: Self { self }

    static var formCases: [Self] {
        [.allMessages, .onlyStarredThreads, .off]
    }

    var localizedText: Text {
        switch self {
        case .off:
            Text("Off")
        case .allMessages:
            Text("All Messages")
        case .onlyStarredThreads:
            Text("Only Starred Threads")
        }
    }
}

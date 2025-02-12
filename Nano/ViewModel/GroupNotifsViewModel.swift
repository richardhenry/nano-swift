//
//  GroupNotifsViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/3/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class GroupNotifsViewModel: ViewModelExpressible {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var shouldHandleChanges = true
    var groupId: GroupID

    var notifs: GroupNotifsValue = .onlyStarredThreads {
        didSet { handleChange(.notifs, oldValue: oldValue, newValue: notifs) }
    }

    var mentionNotifs = false {
        didSet { handleChange(.mentionNotifs, oldValue: oldValue, newValue: mentionNotifs) }
    }

    var replyNotifs = false {
        didSet { handleChange(.replyNotifs, oldValue: oldValue, newValue: replyNotifs) }
    }

    var reactionNotifs = false {
        didSet { handleChange(.reactionNotifs, oldValue: oldValue, newValue: reactionNotifs) }
    }

    var starOnReply = false {
        didSet { handleChange(.starOnReply, oldValue: oldValue, newValue: starOnReply) }
    }

    init(groupId: GroupID) {
        self.groupId = groupId
    }

    func update() throws {
        try dataStore.read { db in
            try fetch(db)
        }
    }

    func fetch(_ db: Database) throws {
        shouldHandleChanges = false
        defer { shouldHandleChanges = true }

        notifs = try GroupSettingModel.fetchValue(
            db,
            groupId: groupId,
            settingType: .notifs,
            defaultValue: .default
        )

        mentionNotifs = try GroupSettingModel.fetchValue(
            db,
            groupId: groupId,
            settingType: .mentionNotifs,
            defaultValue: true
        )

        replyNotifs = try GroupSettingModel.fetchValue(
            db,
            groupId: groupId,
            settingType: .replyNotifs,
            defaultValue: true
        )

        reactionNotifs = try GroupSettingModel.fetchValue(
            db,
            groupId: groupId,
            settingType: .reactionNotifs,
            defaultValue: true
        )

        starOnReply = try GroupSettingModel.fetchValue(
            db,
            groupId: groupId,
            settingType: .starOnReply,
            defaultValue: true
        )
    }

    func handleChange<Value: SettingValue>(
        _ settingType: GroupSettingType,
        oldValue: Value,
        newValue: Value
    ) {
        guard shouldHandleChanges, oldValue != newValue else { return }

        GroupSettingUseCase(
            groupId: groupId,
            settingType: settingType,
            value: newValue,
            dataStore: dataStore
        )
        .detachedTask()
    }
}

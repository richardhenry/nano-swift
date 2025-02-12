//
//  MentionPickerViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/8/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class MentionPickerViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value = [UserModel]()
    var groupId: GroupID
    var searchText = ""
    var selectedUserId: UserID?
    weak var compose: ComposeViewModel?

    var selectedIndex: Int? {
        value.firstIndex { $0.id == selectedUserId }
    }

    var isPresented: Bool {
        true
    }

    init(groupId: GroupID) {
        self.groupId = groupId
    }

    func fetch(_ db: Database) throws -> [UserModel] {
        try MentionListQuery(groupId: groupId, searchText: searchText).fetch(db)
    }

    func selectPrevious() {
        guard let index = selectedIndex, index > 0 else {
            selectedUserId = value.last?.id
            return
        }

        selectedUserId = value[index - 1].id
    }

    func selectNext() {
        guard let index = selectedIndex, index < value.endIndex - 1 else {
            selectedUserId = value.first?.id
            return
        }

        selectedUserId = value[index + 1].id
    }

    func acceptSelection() -> Bool {
        guard let user = value.first(where: { $0.id == selectedUserId }) else {
            return false
        }

        if compose?.insertMention(user: user) == true {
            selectedUserId = nil
            return true
        } else {
            return false
        }
    }
}

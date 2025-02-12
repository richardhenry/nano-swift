//
//  MemberListViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/7/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class MemberListViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value = [MemberListQuery.Item]()
    var groupId: GroupID
    var searchText = ""

    init(groupId: GroupID) {
        self.groupId = groupId
    }

    func fetch(_ db: Database) throws -> [MemberListQuery.Item] {
        try MemberListQuery(groupId: groupId, searchText: searchText).fetch(db)
    }
}

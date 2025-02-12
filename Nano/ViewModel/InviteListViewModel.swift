//
//  InviteListViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/8/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class InviteListViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value = [InviteModel]()
    var groupId: GroupID

    init(groupId: GroupID) {
        self.groupId = groupId
    }

    func fetch(_ db: Database) throws -> [InviteModel] {
        try InviteListQuery(groupId: groupId).fetch(db)
    }
}

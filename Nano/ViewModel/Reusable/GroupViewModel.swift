//
//  GroupViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/7/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class GroupViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value: GroupModel?
    var groupId: GroupID?

    init(groupId: GroupID?) {
        self.groupId = groupId
    }

    func fetch(_ db: Database) throws -> GroupModel? {
        guard let groupId = groupId else { return nil }
        return try GroupModel.fetchOne(db, id: groupId)
    }
}

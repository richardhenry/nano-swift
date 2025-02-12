//
//  MemberViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/7/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class MemberViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value: MemberModel?
    let groupId: GroupID
    let userId: UserID

    init(groupId: GroupID, userId: UserID) {
        self.groupId = groupId
        self.userId = userId
    }

    func fetch(_ db: Database) throws -> MemberModel? {
        try MemberModel.fetchOne(db, groupId: groupId, userId: userId, state: .live)
    }
}

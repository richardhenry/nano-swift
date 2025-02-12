//
//  ReactionSelectedViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/8/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class ReactionSelectedViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value = [ReactionModel]()
    var groupId: GroupID
    var targetId: MessageID

    init(groupId: GroupID, targetId: MessageID) {
        self.groupId = groupId
        self.targetId = targetId
    }

    func fetch(_ db: Database) throws -> [ReactionModel] {
        let session = try SessionModel.fetchExpect(db)

        return try ReactionModel.fetchAll(
            db,
            groupId: groupId,
            targetId: targetId,
            userId: session.userId
        )
    }
}

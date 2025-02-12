//
//  ReactionListViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/8/24.
//

import Foundation
import GRDB
import NanoKit
import OrderedCollections

@Observable final class ReactionListViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value = OrderedDictionary<String, [ReactionListQuery.Item]>()
    var groupId: GroupID
    var targetId: MessageID

    var sections: [String] {
        Array(value.keys)
    }

    init(groupId: GroupID, targetId: MessageID) {
        self.groupId = groupId
        self.targetId = targetId
    }

    func items(in section: String) -> [ReactionListQuery.Item] {
        if let items = value[section] {
            return items
        } else {
            assertionFailure()
            return []
        }
    }

    func fetch(_ db: Database) throws -> OrderedDictionary<String, [ReactionListQuery.Item]> {
        let items = try ReactionListQuery(groupId: groupId, targetId: targetId).fetch(db)

        var result = OrderedDictionary<String, [ReactionListQuery.Item]>()
        for item in items {
            guard let base = item.reaction.base else {
                continue
            }
            if result[base] == nil {
                result[base] = []
            }
            result[base]!.append(item)
        }
        result.sort { $0.value.count < $1.value.count }
        result.reverse()

        return result
    }
}

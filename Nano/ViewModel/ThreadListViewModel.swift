//
//  ThreadListViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/9/24.
//

import Combine
import Foundation
import GRDB
import NanoKit

@Observable final class ThreadListViewModel: QueryViewModel {
    enum Item: Identifiable, Equatable {
        var id: String {
            switch self {
            case .thread(let item):
                "0:\(item.thread.id)"
            }
        }

        case thread(ThreadListQuery.Item)
    }

    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value: [Item]?
    var groupId: GroupID?
    var searchText = ""

    init(groupId: GroupID?) {
        self.groupId = groupId
    }

    func fetch(_ db: Database) throws -> [Item]? {
        guard let groupId = groupId else { return nil }

        let threadQuery = try ThreadListQuery(groupId: groupId, searchText: searchText).fetch(db)

        var result: [Item] = []
        for threadItem in threadQuery {
            result.append(.thread(threadItem))
        }

        return result
    }
}

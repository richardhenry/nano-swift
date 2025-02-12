//
//  MessageListViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/8/24.
//

import Combine
import Foundation
import GRDB
import NanoCore
import NanoKit

@Observable final class MessageListViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value = [Item]()
    var groupId: GroupID?
    var threadId: ThreadID?

    init(groupId: GroupID?, threadId: ThreadID?) {
        self.groupId = groupId
        self.threadId = threadId
    }

    enum Item: Identifiable, Equatable {
        var id: String {
            switch self {
            case .dateBreak(let timestamp):
                "0:\(timestamp)"
            case .message(let message, _, _, _):
                "1:\(message.id)"
            case .deletedMessage(let message, _):
                "2:\(message.id)"
            }
        }

        case dateBreak(timestamp: Timestamp)
        case message(
            message: MessageModel,
            user: UserModel?,
            reactions: [ReactionAggregatedQuery.Item]?,
            header: Bool
        )
        case deletedMessage(
            message: MessageModel,
            deletedByUser: UserModel?
        )
    }

    func fetch(_ db: Database) throws -> [Item] {
        guard let groupId, let threadId else { return [] }

        let items = try MessageListQuery(
            groupId: groupId,
            threadId: threadId
        )
        .fetch(db)

        var results = [Item]()

        for (idx, item) in items.enumerated() {
            if idx == 0
                || TimestampFormatter.numberOfCalendarDays(
                    from: items[idx - 1].message.createTimestamp,
                    to: item.message.createTimestamp
                ) != 0
            {
                results.append(.dateBreak(timestamp: item.message.createTimestamp))
            }

            if !item.message.isDeleted {
                results.append(
                    .message(
                        message: item.message,
                        user: item.user,
                        reactions: item.reactions,
                        header: (idx == 0
                            || items[idx - 1].user?.id != item.user?.id
                            || item.message.createTimestamp
                                - items[idx - 1].message.createTimestamp > .minute
                            || items[idx - 1].message.isDeleted)
                    )
                )
            } else {
                results.append(
                    .deletedMessage(
                        message: item.message,
                        deletedByUser: item.user
                    )
                )
            }
        }

        return results
    }
}

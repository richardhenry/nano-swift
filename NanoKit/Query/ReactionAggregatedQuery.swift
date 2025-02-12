//
//  ReactionAggregatedQuery.swift
//  NanoKit
//
//  Created by Richard Henry on 5/7/24.
//

import Foundation
import GRDB
import NanoCore
import OrderedCollections

public struct ReactionAggregatedQuery: Query {
    public var groupId: GroupID
    public var threadId: ThreadID

    public init(groupId: GroupID, threadId: ThreadID) {
        self.groupId = groupId
        self.threadId = threadId
    }

    public struct Item: Identifiable, Equatable {
        public var id: String { base }
        public var base: String
        public var count: UInt
        public var variations: OrderedSet<String>
        public var timestamp: Timestamp
        public var includesViewer: Bool
    }

    public func fetch(_ db: Database) throws -> [MessageID: [Item]] {
        let session = try SessionModel.fetchExpect(db)

        let reactions = try ReactionModel.fetchAll(
            db,
            groupId: groupId,
            threadId: threadId
        )

        var aggr = [MessageID: [String: Item]]()
        for reaction in reactions {
            guard let base = reaction.base,
                let targetId = reaction.targetId,
                reaction.sendState != .pendingDelete
            else {
                log(.warning, "Skipping deleted reaction: \(reaction)")
                continue
            }

            if aggr[targetId] == nil {
                aggr[targetId] = [:]
            }

            if aggr[targetId]![base] == nil {
                aggr[targetId]![base] = Item(
                    base: base,
                    count: 1,
                    variations: [reaction.variation ?? base],
                    timestamp: reaction.createTimestamp,
                    includesViewer: reaction.userId == session.userId
                )
            } else {
                aggr[targetId]![base]!.count += 1

                aggr[targetId]![base]!
                    .variations
                    .append(reaction.variation ?? base)

                if reaction.userId == session.userId {
                    aggr[targetId]![base]!.includesViewer = true
                }
            }
        }

        return aggr.mapValues {
            $0.values.sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.timestamp < rhs.timestamp
                } else {
                    return rhs.count < lhs.count
                }
            }
        }
    }
}

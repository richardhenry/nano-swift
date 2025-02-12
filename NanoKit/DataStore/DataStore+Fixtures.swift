//
//  DataStore+Fixtures.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

#if DEBUG
import Foundation
import GRDB
import CryptoKit
import NanoCrypto
import NanoCore

extension DataStore {
    private var fixtureEpoch: Timestamp { 1_704_233_276_674 }

    func installFixtures() throws {
        try dbWriter.write { db in
            if try db.tableExists("fixtures") == false {
                try db.create(table: "fixtures", ifNotExists: true) { t in
                    t.column("identifier").primaryKey()
                }
                try _installFixtures(db)
            }
        }
    }

    private func _installFixtures(_ db: Database) throws {
        let richard = try makeUser(name: "Richard", db: db)
        let marc = try makeUser(name: "Marc", db: db)
        let helen = try makeUser(name: "Helen", db: db)

        let devTeam = try makeGroup(name: "Dev Team", isUnread: true, db: db)
        let bugs = try makeGroup(name: "Bugs", db: db)
        let podcast = try makeGroup(name: "Podcast", isUnread: true, db: db)
        let apple = try makeGroup(name: "Apple", isUnread: true, db: db)
        let ai = try makeGroup(name: "AI", db: db)
        let tvShows = try makeGroup(name: "TV Shows & Movies", isUnread: true, db: db)
        let electionNight = try makeGroup(name: "Election Night", db: db)
        let basketball = try makeGroup(name: "Basketball", db: db)

        for groupId in previewGroupIdToThreadIds.keys {
            try addMembers(groupId: groupId, userIds: previewUserIds, db: db)
        }

        try makeThread(
            group: devTeam,
            messages: [
                .text(marc, "Nano is really cool", .minutes(2)),
                .text(richard, "Yes, I agree", .minutes(3)),
                .text(helen, "It’s pretty great", .minutes(4)),
            ],
            db: db
        )

        try makeThread(group: bugs, messages: [.text(richard, "Bugs test thread", 0)], db: db)

        try makeThread(
            group: devTeam,
            messages: [
                .text(marc, "Dinner tonight?", .minutes(1)),
                .text(richard, "Let’s do it", .minutes(2)),
            ],
            db: db
        )

        try makeThread(
            group: podcast,
            messages: [.text(richard, "Podcast test thread", 0)],
            db: db
        )

        try makeThread(group: apple, messages: [.text(richard, "Apple test thread", 0)], db: db)

        try makeThread(group: ai, messages: [.text(richard, "AI test thread", 0)], db: db)

        try makeThread(
            group: tvShows,
            messages: [.text(richard, "TV shows test thread", 0)],
            db: db
        )

        try makeThread(
            group: electionNight,
            messages: [.text(richard, "Election Night test thread", 0)],
            db: db
        )

        try makeThread(
            group: basketball,
            messages: [.text(richard, "Basketball test thread", 0)],
            db: db
        )
    }

    private func makeUser(
        name: String,
        userId: UserID = UserID(),
        db: Database
    ) throws -> UserModel {
        let model = try UserModel(id: userId, name: name, image: nil).saved(db)
        previewUserIds.append(model.id)
        return model
    }

    private func makeGroup(
        name: String,
        isUnread: Bool = false,
        db: Database
    ) throws -> GroupModel {
        let group = try GroupModel(
            id: GroupID(),
            name: name,
            isPending: false,
            isUnread: isUnread
        )
        .saved(db)
        previewGroupIdToThreadIds[group.id] = []
        return group
    }

    private func addMembers(groupId: GroupID, userIds: [UserID], db: Database) throws {
        for userId in userIds {
            let storeKey = Curve25519.KeyAgreement.PrivateKey()
            let storeKeyKyber = try Kyber1024.pair()
            let authKey = Curve25519.KeyAgreement.PrivateKey()

            try MemberModel(
                groupId: groupId,
                userId: userId,
                storeKey: storeKey.publicKey,
                storeKeyKyber: storeKeyKyber.publicKey,
                authKey: authKey.publicKey,
                timestamp: .now()
            )
            .save(db)
        }
    }

    @discardableResult private func makeThread(
        group: GroupModel,
        messages: [FixtureMessage],
        isUnread: Bool = false,
        db: Database
    ) throws -> ThreadModel {
        let threadId = ThreadID()
        previewGroupIdToThreadIds[group.id] =
            (previewGroupIdToThreadIds[group.id] ?? []) + [threadId]

        let result = try messages.enumerated()
            .map {
                try MessageModel(
                    groupId: group.id,
                    id: MessageID(),
                    threadId: threadId,
                    userId: $0.element.model.id,
                    deletedByUserId: nil,
                    isRoot: $0.offset == 0,
                    text: $0.element.text,
                    attachments: nil,
                    links: nil,
                    mentions: nil,
                    sendState: .sent,
                    createTimestamp: fixtureEpoch + $0.element.offset,
                    editTimestamp: nil
                )
                .saved(db)
            }

        let timestamp = result.last?.createTimestamp ?? fixtureEpoch

        return try ThreadModel(
            groupId: group.id,
            id: threadId,
            subject: result.first?.renderPlaintext(),
            isUnread: isUnread,
            unreadCount: min(1, messages.count),
            totalCount: messages.count,
            lastMessageId: result.last?.id,
            badgeTimestamp: timestamp
        )
        .saved(db)
    }
}

private enum FixtureMessage {
    case text(UserModel, String, Timestamp)

    var model: UserModel {
        switch self {
        case .text(let model, _, _): return model
        }
    }

    var text: String {
        switch self {
        case .text(_, let text, _): return text
        }
    }

    var offset: Timestamp {
        switch self {
        case .text(_, _, let offset): return offset
        }
    }
}
#endif

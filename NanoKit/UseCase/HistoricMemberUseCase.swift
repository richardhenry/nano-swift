//
//  HistoricMemberUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/22/24.
//

import Foundation
import GRDB
import NanoCore
import NanoCrypto

public struct HistoricMemberUseCase: UseCase {
    public var groupId: GroupID
    public var userId: UserID
    public var timestamp: Timestamp
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public func run() async throws {
        try await dataStore.write { db in
            let member = try MemberModel.fetchExpect(
                db,
                groupId: groupId,
                userId: userId,
                state: .live
            )

            guard member.timestamp < timestamp else {
                throw error("Historic member superceded. Group ID: \(groupId) User ID: \(userId)")
            }

            let session = try SessionModel.fetchExpect(db)

            log(.info, "Removing member. Group ID: \(member.groupId) User ID: \(member.userId)")

            if session.userId == userId {
                try handleViewerLeave(db)
            } else {
                try MemberModel.updateState(
                    db,
                    groupId: groupId,
                    userId: userId,
                    newState: .historic,
                    timestamp: timestamp
                )
                try VirtualMemberModel.deleteAll(db, groupId: groupId, ownedByUserId: userId)
                try EpochDirtyModel.set(db, id: groupId, dirtyTimestamp: timestamp)
            }
        }

        try await EpochCreateUseCase(dataStore: dataStore, keychainStorage: keychainStorage).run()
    }

    func handleViewerLeave(_ db: Database) throws {
        for epoch in try EpochModel.fetchAll(db, groupId: groupId, includeDiscontiguous: true) {
            try KeychainStorage.shared.delete(.epochRootKey(epoch.id))
        }

        try GroupModel.deleteOne(db, id: groupId)
        try EpochModel.deleteAll(db, groupId: groupId)
        try EpochMacModel.deleteAll(db, groupId: groupId)
        try MetadataModel.deleteOne(db, id: groupId)
        try MemberModel.deleteAll(db, groupId: groupId)
        try VirtualMemberModel.deleteAll(db, groupId: groupId)
        try RoleModel.deleteOne(db, id: groupId)
        try GroupSettingModel.deleteAll(db, groupId: groupId)
        try ThreadSettingModel.deleteAll(db, groupId: groupId)
        try InviteModel.deleteAll(db, groupId: groupId)
        try MessageModel.deleteAll(db, groupId: groupId)
        try ReactionModel.deleteAll(db, groupId: groupId)
        try ThreadModel.deleteAll(db, groupId: groupId)
        try GroupActivityModel.deleteAll(db, id: groupId)
        try ThreadActivityModel.deleteAll(db, groupId: groupId)
        try CursorModel.deleteAll(db, fetchType: .threadActivity, path: groupId)
        try CursorModel.deleteAll(db, fetchType: .member, path: groupId)
        try CursorModel.deleteAll(db, fetchType: .virtualMember, path: groupId)
        try CursorModel.deleteAll(db, fetchType: .message, withPathPrefix: groupId)
    }
}

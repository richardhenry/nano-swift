//
//  MemberPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/5/24.
//

import CryptoKit
import Foundation
import NanoCore
import NanoCrypto

public enum MemberState: Int, Codable {
    case live = 0
    case historic = 1
}

public struct MemberPayload: Codable, SignedPayload {
    public var groupId: GroupID
    public var userId: UserID
    public var storeKey: Curve25519.KeyAgreement.PublicKey
    public var storeKeyKyber: Kyber1024.PublicKey
    public var authKey: Curve25519.KeyAgreement.PublicKey
    public var signature: Data
    public var state: MemberState
    public var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case userId = "u"
        case storeKey = "t"
        case storeKeyKyber = "k"
        case authKey = "a"
        case signature = "s"
        case state = "e"
        case timestamp = "x"
    }

    public var signedData: Data {
        var out = Data(useCaseByte: .memberSignature)
        out.append(groupId.data)
        out.append(userId.data)
        out.append(storeKey.rawRepresentation)
        out.append(storeKeyKyber.rawRepresentation)
        out.append(authKey.rawRepresentation)
        return out
    }

    public var signingUserId: UserID {
        userId
    }

    public init(member: MemberModel, signingKey: Curve25519.Signing.PrivateKey) throws {
        groupId = member.groupId
        userId = member.userId
        storeKey = member.storeKey
        storeKeyKyber = member.storeKeyKyber
        authKey = member.authKey
        state = member.state
        timestamp = member.timestamp

        signature = Data()
        signature = try signingKey.signature(for: signedData)
    }
}

extension MemberPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        switch state {
        case .live:
            let userKey = try await DataStore.shared.read { db in
                try fetchSigningKey(db)
            }

            try validateSignature(with: userKey)

            try await DataStore.shared.write { db in
                do {
                    try MemberModel(payload: self).insert(db, onConflict: .fail)
                } catch {
                    // Reactivate the existing group member.
                    try MemberModel.updateState(
                        db,
                        groupId: groupId,
                        userId: userId,
                        newState: .live,
                        timestamp: timestamp
                    )
                }
            }
        case .historic:
            try await HistoricMemberUseCase(
                groupId: groupId,
                userId: userId,
                timestamp: timestamp,
                dataStore: .shared,
                keychainStorage: .shared
            )
            .run()
        }
    }
}

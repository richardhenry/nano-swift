//
//  VirtualMemberPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/16/24.
//

import CryptoKit
import Foundation
import MessagePack
import NanoCore
import NanoCrypto

public struct VirtualMemberPayload: Codable, SignedPayload {
    public var groupId: GroupID
    public var virtualId: VirtualMemberID
    public var ownerUserId: UserID
    public var epochId: EpochID
    public var metadataEpochId: EpochID
    public var storeKey: Curve25519.KeyAgreement.PublicKey
    public var storeKeyKyber: Kyber1024.PublicKey
    /// The secrets for this virtual member. If nil, the virtual member is no longer valid and should be deleted by the client.
    public var secrets: XChaChaPoly.SealedBox?
    public var signature: Data
    public var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case groupId = "g"
        case virtualId = "v"
        case ownerUserId = "u"
        case epochId = "e"
        case metadataEpochId = "m"
        case storeKey = "t"
        case storeKeyKyber = "k"
        case secrets = "c"
        case signature = "s"
        case timestamp = "x"
    }

    public var signedData: Data {
        get throws {
            var out = Data(useCaseByte: .virtualMemberSignature)
            out.append(groupId.data)
            out.append(virtualId.data)
            out.append(ownerUserId.data)
            out.append(epochId.data)
            out.append(metadataEpochId.data)
            out.append(storeKey.rawRepresentation)
            out.append(storeKeyKyber.rawRepresentation)
            out.append(try expectSecrets().combined)
            return out
        }
    }

    public var signingUserId: UserID {
        ownerUserId
    }

    public init(
        groupId: GroupID,
        virtualId: VirtualMemberID,
        ownerUserId: UserID,
        epochId: EpochID,
        metadataEpochId: EpochID,
        storeKey: Curve25519.KeyAgreement.PublicKey,
        storeKeyKyber: Kyber1024.PublicKey,
        secrets: XChaChaPoly.SealedBox,
        timestamp: Timestamp,
        signingKey: Curve25519.Signing.PrivateKey
    ) throws {
        self.groupId = groupId
        self.virtualId = virtualId
        self.ownerUserId = ownerUserId
        self.epochId = epochId
        self.metadataEpochId = metadataEpochId
        self.storeKey = storeKey
        self.storeKeyKyber = storeKeyKyber
        self.secrets = secrets
        self.timestamp = timestamp

        signature = Data()
        signature = try signingKey.signature(for: signedData)
    }

    public func expectSecrets() throws -> XChaChaPoly.SealedBox {
        if let secrets {
            return secrets
        } else {
            throw error("This virtual member has been deleted and does not contain any secrets.")
        }
    }
}

extension VirtualMemberPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        if secrets != nil {
            // Handle live virtual member.

            let userKey = try await DataStore.shared.read { db in
                // If the member model doesn't exist, we should throw here.
                _ = try MemberModel.fetchExpect(
                    db,
                    groupId: groupId,
                    userId: ownerUserId,
                    state: .live
                )
                return try UserKeyModel.fetchExpect(db, id: ownerUserId)
            }

            try validateSignature(with: userKey)

            try await DataStore.shared.write { db in
                try VirtualMemberModel(payload: self).insert(db, onConflict: .ignore)
            }
        } else {
            // Handle historic, non-live virtual member.

            try await DataStore.shared.write { db in
                try VirtualMemberModel.deleteOne(db, groupId: groupId, virtualId: virtualId)
            }
        }
    }
}

// MARK: Secrets

extension VirtualMemberPayload {
    public struct Secrets {
        public var epochRootKey: SymmetricKey
        public var metadataEpochRootKey: SymmetricKey
        public var storeKey: Curve25519.KeyAgreement.PrivateKey
        public var storeKeyKyber: Kyber1024.PrivateKey

        public func encrypt(
            virtualId: VirtualMemberID,
            secretKey: SymmetricKey
        ) throws
            -> XChaChaPoly.SealedBox
        {
            let data = try SecureBytePack([
                epochRootKey,
                metadataEpochRootKey,
                storeKey,
                storeKeyKyber,
            ])
            .pack()

            return try XChaChaPoly.seal(
                data,
                using: secretKey,
                authenticating: Data(
                    "virtual_member_secrets_\(virtualId.base64EncodedString)".utf8
                )
            )
        }
    }

    public func decryptSecrets(secretKey: SymmetricKey) throws -> Secrets {
        let data = try XChaChaPoly.open(
            try expectSecrets(),
            using: secretKey,
            authenticating: Data(
                "virtual_member_secrets_\(virtualId.base64EncodedString)".utf8
            ),
            intoSecureMemory: true
        )

        let pack = try SecureBytePack(
            from: data,
            layout: [
                .item(SymmetricKey.self, sizeBytes: 32),
                .item(SymmetricKey.self, sizeBytes: 32),
                .item(Curve25519.KeyAgreement.PrivateKey.self),
                .item(Kyber1024.PrivateKey.self),
            ]
        )

        return Secrets(
            epochRootKey: try pack.item(at: 0),
            metadataEpochRootKey: try pack.item(at: 1),
            storeKey: try pack.item(at: 2),
            storeKeyKyber: try pack.item(at: 3)
        )
    }
}

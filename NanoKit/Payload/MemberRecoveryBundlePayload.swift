//
//  MemberRecoveryBundlePayload.swift
//  NanoKit
//
//  Created by Richard Henry on 4/25/24.
//

import Foundation

public struct MemberRecoveryBundlePayload: Codable {
    public var group: GroupPayload
    public var member: MemberPayload
    public var metadata: MetadataPayload
    public var epochs: [EpochBundlePayload]
    public var secret: SecretPayload
    public var recovery: MemberRecoveryPayload

    enum CodingKeys: String, CodingKey {
        case group = "g"
        case member = "m"
        case metadata = "d"
        case epochs = "e"
        case secret = "s"
        case recovery = "r"
    }
}

extension MemberRecoveryBundlePayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        try await MemberRecoveryUseCase(bundle: self).run()
    }
}

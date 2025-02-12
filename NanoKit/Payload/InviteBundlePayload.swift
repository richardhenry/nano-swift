//
//  InviteResponsePayload.swift
//  Nano
//
//  Created by Richard Henry on 1/17/24.
//

import Foundation

public struct InviteBundlePayload: Codable {
    public var invite: InvitePayload
    public var group: GroupPayload
    public var metadata: MetadataPayload
    public var virtualMember: VirtualMemberPayload
    public var epochs: [EpochBundlePayload]
    public var existingMember: MemberPayload?
    public var secret: SecretPayload?

    enum CodingKeys: String, CodingKey {
        case invite = "i"
        case group = "g"
        case metadata = "d"
        case virtualMember = "v"
        case epochs = "e"
        case existingMember = "h"
        case secret = "s"
    }
}

extension InviteBundlePayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {}
}

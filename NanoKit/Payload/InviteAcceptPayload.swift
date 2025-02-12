//
//  InviteAcceptPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/17/24.
//

import CryptoKit
import Foundation

public struct InviteAcceptPayload: Codable {
    public var token: Data
    public var member: MemberPayload
    public var secret: SecretPayload
    public var recovery: MemberRecoveryPayload
    public var epochId: EpochID
    public var mac: Data

    enum CodingKeys: String, CodingKey {
        case token = "t"
        case member = "m"
        case secret = "s"
        case recovery = "r"
        case epochId = "e"
        case mac = "a"
    }
}

extension InviteAcceptPayload: ClientEventPayload {}

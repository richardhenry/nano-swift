//
//  RegisterGetPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/17/24.
//

import Foundation

public struct RegisterValidatePayload: Codable {
    public struct Challenge: Codable {
        public var userId: UserID
        public var recoverySecret: SecretPayload
        public var signingSecret: SecretPayload

        enum CodingKeys: String, CodingKey {
            case userId = "u"
            case recoverySecret = "r"
            case signingSecret = "g"
        }
    }

    public var challenge: Challenge?

    enum CodingKeys: String, CodingKey {
        case challenge = "c"
    }
}

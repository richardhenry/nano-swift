//
//  RegisterNewPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/17/24.
//

import Foundation

public struct RegisterNewPayload: Codable {
    public var user: UserPayload
    public var userKey: UserKeyPayload
    public var recoverySecret: SecretPayload
    public var signingSecret: SecretPayload

    enum CodingKeys: String, CodingKey {
        case user = "u"
        case userKey = "k"
        case recoverySecret = "r"
        case signingSecret = "g"
    }
}

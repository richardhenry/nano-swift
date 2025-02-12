//
//  RegisterSendPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/17/24.
//

import Foundation

public struct RegisterSendPayload: Codable {
    public var email: String

    public init(email: String) {
        self.email = email
    }

    enum CodingKeys: String, CodingKey {
        case email = "e"
    }
}

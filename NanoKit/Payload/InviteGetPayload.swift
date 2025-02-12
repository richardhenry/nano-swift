//
//  InviteRequestPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/17/24.
//

import CryptoKit
import Foundation

public struct InviteGetPayload: Codable {
    public var token: Data

    enum CodingKeys: String, CodingKey {
        case token = "t"
    }
}

extension InviteGetPayload: ClientEventPayload {}

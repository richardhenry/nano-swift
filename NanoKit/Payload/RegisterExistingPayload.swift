//
//  RegisterExistingPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 4/25/24.
//

import Foundation

public struct RegisterExistingPayload: Codable {
    public var signature: Data

    enum CodingKeys: String, CodingKey {
        case signature = "s"
    }
}

//
//  XChaChaPoly+Codable.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/15/24.
//

import CryptoKit
import Foundation

extension XChaChaPoly.SealedBox: Codable {
    public init(from decoder: Decoder) throws {
        let combined = try decoder.singleValueContainer().decode(Data.self)
        self = try Self.init(combined: combined)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(combined)
    }
}

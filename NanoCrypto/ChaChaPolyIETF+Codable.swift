//
//  ChaChaPolyIETF+Codable.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/21/24.
//

import Foundation

extension ChaChaPolyIETF.SealedBox: Codable {
    public init(from decoder: Decoder) throws {
        let combined = try decoder.singleValueContainer().decode(Data.self)
        self = try Self.init(combined: combined)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(combined)
    }
}

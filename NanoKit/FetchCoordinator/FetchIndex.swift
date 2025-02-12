//
//  FetchIndex.swift
//  NanoKit
//
//  Created by Richard Henry on 5/9/24.
//

import Foundation
import NanoCore

public struct FetchIndex: Codable, Equatable {
    public var timestamp: Timestamp
    public var id: AnyID

    public init(timestamp: Timestamp, id: any UniqueIdentifier) {
        self.timestamp = timestamp
        self.id = id.eraseToAny()
    }

    public init(timestamp: Timestamp, id: AnyID) {
        self.timestamp = timestamp
        self.id = id
    }

    enum CodingKeys: String, CodingKey {
        case timestamp = "x"
        case id = "i"
    }
}

//
//  FetchRequestPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 2/28/24.
//

import Foundation

public struct FetchRequestPayload: Codable {
    public var key: FetchKey
    public var start: FetchIndex?
    public var end: FetchIndex?
    public var isPersistent: Bool

    public init(
        key: FetchKey,
        start: FetchIndex?,
        end: FetchIndex?,
        isPersistent: Bool
    ) {
        self.key = key
        self.start = start
        self.end = end
        self.isPersistent = isPersistent
    }

    enum CodingKeys: String, CodingKey {
        case key = "k"
        case start = "s"
        case end = "e"
        case isPersistent = "p"
    }
}

extension FetchRequestPayload: ClientEventPayload {}

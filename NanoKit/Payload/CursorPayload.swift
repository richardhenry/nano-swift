//
//  CursorPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 2/28/24.
//

import Foundation
import GRDB

public struct CursorPayload: Codable {
    public var key: FetchKey
    public var start: FetchIndex?
    public var end: FetchIndex?

    public init(
        key: FetchKey,
        start: FetchIndex,
        end: FetchIndex?
    ) {
        self.key = key
        self.start = start
        self.end = end
    }

    enum CodingKeys: String, CodingKey {
        case key = "k"
        case start = "s"
        case end = "e"
    }
}

extension CursorPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        guard let cursor = CursorModel(payload: self) else { return }

        try await DataStore.shared.write { db in
            var cursor = cursor
            try cursor.extend(db)
            try cursor.save(db)
        }
    }
}

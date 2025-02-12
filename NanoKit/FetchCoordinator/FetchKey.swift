//
//  FetchKey.swift
//  NanoKit
//
//  Created by Richard Henry on 4/3/24.
//

import Foundation

public struct FetchKey: Codable, Equatable {
    public var fetchType: FetchType
    public var path: FetchPath

    public init(fetchType: FetchType, path: any UniqueIdentifier...) {
        self.fetchType = fetchType
        self.path = FetchPath(path)
    }

    public init(fetchType: FetchType, path: FetchPath) {
        self.fetchType = fetchType
        self.path = path
    }

    enum CodingKeys: String, CodingKey {
        case fetchType = "t"
        case path = "p"
    }
}

extension FetchKey: ClientEventPayload {}

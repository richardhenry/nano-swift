//
//  ThreadID.swift
//  NanoKit
//
//  Created by Richard Henry on 1/27/24.
//

import Foundation

public struct ThreadID: UniqueIdentifier {
    public var rawValue: UUID

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

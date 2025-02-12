//
//  RequestID.swift
//  NanoKit
//
//  Created by Richard Henry on 1/27/24.
//

import Foundation

public struct RequestID: UniqueIdentifier {
    public var rawValue: UUID

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

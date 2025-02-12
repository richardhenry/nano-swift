//
//  ViewID.swift
//  NanoKit
//
//  Created by Richard Henry on 1/30/24.
//

import Foundation

public struct ViewID: UniqueIdentifier {
    public var rawValue: UUID

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

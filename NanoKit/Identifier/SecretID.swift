//
//  SecretID.swift
//  NanoKit
//
//  Created by Richard Henry on 4/23/24.
//

import Foundation

public struct SecretID: UniqueIdentifier {
    public var rawValue: UUID

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

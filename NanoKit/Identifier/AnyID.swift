//
//  AnyID.swift
//  NanoKit
//
//  Created by Richard Henry on 2/28/24.
//

import Foundation
import GRDB

public struct AnyID: UniqueIdentifier {
    public var rawValue: UUID

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }

    public func asType<OtherID: UniqueIdentifier>() -> OtherID {
        OtherID(rawValue: rawValue)!
    }

    public func asType() -> AnyID { self }

    public func eraseToAny() -> AnyID { self }
}

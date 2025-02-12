//
//  Data+UseCaseByte.swift
//  Nano
//
//  Created by Richard Henry on 1/6/24.
//

import Foundation

public enum UseCaseByte: UInt8 {
    case memberSignature = 0
    case virtualMemberSignature = 1
    case messageSignature = 2
    case reactionSignature = 3
    case metadataSignature = 4
    case epochSignature = 5
    case registerSignature = 6
}

extension Data {
    public init(useCaseByte: UseCaseByte) {
        self.init([useCaseByte.rawValue])
    }

    public func withUseCaseByte(_ useCaseByte: UseCaseByte) -> Data {
        var out = Data([useCaseByte.rawValue])
        out.append(self)
        return out
    }
}

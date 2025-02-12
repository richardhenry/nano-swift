//
//  UnwrapOrThrow.swift
//  NanoCore
//
//  Created by Richard Henry on 1/30/24.
//

import Foundation

infix operator ?! : NilCoalescingPrecedence

@inlinable
public func ?! <T>(value: T?, error: @autoclosure () -> Error) throws -> T {
    if let value = value {
        return value
    } else {
        throw error()
    }
}

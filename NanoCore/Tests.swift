//
//  Tests.swift
//  NanoCore
//
//  Created by Richard Henry on 3/30/24.
//

import Foundation

@inlinable
public func isRunningInTests() -> Bool {
    NSClassFromString("XCTestCase") != nil
}

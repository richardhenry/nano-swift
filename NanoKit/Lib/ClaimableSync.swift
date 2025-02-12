//
//  ClaimableSync.swift
//  NanoKit
//
//  Created by Richard Henry on 2/8/24.
//

import Foundation

public final class ClaimableSync {
    private let lock = NSLock()
    private var isClaimed = false

    public func claim() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if isClaimed {
            return false
        } else {
            isClaimed = true
            return true
        }
    }
}

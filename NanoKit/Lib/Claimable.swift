//
//  Claimable.swift
//  NanoKit
//
//  Created by Richard Henry on 2/8/24.
//

import Foundation

public actor Claimable {
    private var isClaimed = false

    public func claim() -> Bool {
        if isClaimed {
            return false
        } else {
            isClaimed = true
            return true
        }
    }
}

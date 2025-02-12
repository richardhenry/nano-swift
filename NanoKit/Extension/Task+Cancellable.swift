//
//  Task+Cancellable.swift
//  NanoKit
//
//  Created by Richard Henry on 4/10/24.
//

import Combine

extension Task: Cancellable {
    public func cancellable() -> AnyCancellable {
        AnyCancellable(self)
    }
}

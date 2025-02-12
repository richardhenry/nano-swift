//
//  Fetcher.swift
//  NanoKit
//
//  Created by Richard Henry on 5/2/24.
//

import Foundation
import NanoCore

protocol Fetcher {
    var dataStore: DataStore { get }
    func run() async throws
}

extension Fetcher {
    func fetch(
        key: FetchKey,
        isPersistent: Bool
    ) async throws {
        try await FetchRequest(
            key: key,
            isPersistent: isPersistent,
            dataStore: dataStore
        )
        .run()
    }
}

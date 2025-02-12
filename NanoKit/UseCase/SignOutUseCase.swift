//
//  SignOutUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 5/30/24.
//

import Foundation
import NanoCore
import NanoCrypto

public struct SignOutUseCase: UseCase {
    public var dataStore: DataStore
    public var keychainStorage: KeychainStorage

    public init(
        dataStore: DataStore = .shared,
        keychainStorage: KeychainStorage = .shared
    ) {
        self.dataStore = dataStore
        self.keychainStorage = keychainStorage
    }

    public func run() async throws {
        let event = try ClientEvent(eventType: .sessionDelete, payload: nil)
        try await event.send()
    }
}

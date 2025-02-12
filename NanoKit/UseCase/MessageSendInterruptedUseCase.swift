//
//  MessageSendInterruptedUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/8/24.
//

import Foundation

public struct MessageSendInterruptedUseCase: UseCase {
    public var dataStore: DataStore

    public init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    public func run() async throws {
        try await dataStore.write { db in
            try MessageModel.setSendStateForInterrupted(db)
        }
    }
}

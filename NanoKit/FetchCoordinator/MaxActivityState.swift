//
//  MaxActivityState.swift
//  NanoKit
//
//  Created by Richard Henry on 5/21/24.
//

import Combine
import Foundation
import GRDB
import NanoCore

public class MaxActivityState {
    public static let shared = MaxActivityState(dataStore: .shared)

    public let timestamp = CurrentValueSubject<Timestamp?, Never>(nil)

    private var dataStore: DataStore
    private var observationCancellable: AnyCancellable?

    public init(dataStore: DataStore) {
        self.dataStore = dataStore

        self.observationCancellable =
            ValueObservation
            .tracking(fetch)
            .publisher(in: dataStore.dbReader)
            .sink { completion in
                if case .failure(let error) = completion {
                    log(error)
                }
            } receiveValue: { [weak self] value in
                self?.timestamp.value = value
            }
    }

    func fetch(_ db: Database) throws -> Timestamp? {
        try GroupActivityModel.fetchMaxActivityTimestamp(db)
    }
}

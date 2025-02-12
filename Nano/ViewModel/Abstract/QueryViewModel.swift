//
//  QueryViewModel.swift
//  NanoKit
//
//  Created by Richard Henry on 4/4/24.
//

import Combine
import GRDB
import NanoCore
import NanoKit
import SwiftUI

protocol QueryViewModel: ViewModelExpressible where Result == AnyCancellable {
    associatedtype Value
    /// The most recent value returned by a call to `fetch(_:)`.
    var value: Value { get set }

    /// The value observation publisher for the database. In general you do not need to provide an implementation of this method.
    func publisher() -> AnyPublisher<Value, Error>

    /// Perform a database fetch. Property access will be tracked inside this method, and changes will trigger another fetch. You must implement this method in your view model.
    func fetch(_ db: Database) throws -> Value
}

extension QueryViewModel {
    func publisher() -> AnyPublisher<Value, Error> {
        ValueObservation
            .tracking(fetchWithObservationTracking)
            .publisher(in: dataStore.dbReader, scheduling: .immediate)
            .eraseToAnyPublisher()
    }

    func update() -> AnyCancellable {
        publisher()
            .sink { completion in
                if case .failure(let error) = completion {
                    log(error)
                }
            } receiveValue: { [weak self] value in
                self?.value = value
            }
    }

    func fetchWithObservationTracking(_ db: Database) throws -> Value {
        var fetchError: Error?

        let result: Value? = withObservationTracking {
            do {
                return try fetch(db)
            } catch {
                fetchError = error
                return nil
            }
        } onChange: { [weak self] in
            self?.needsUpdate?()
        }

        if let result = result {
            return result
        } else {
            throw fetchError!
        }
    }
}

//
//  GroupState.swift
//  NanoKit
//
//  Created by Richard Henry on 5/5/24.
//

import Combine
import Foundation
import GRDB
import NanoCore

public class GroupState {
    public static let shared = GroupState(dataStore: .shared)

    public let groupDidBecomeActive = PassthroughSubject<GroupID, Never>()
    public let groupDidBecomeInactive = PassthroughSubject<GroupID, Never>()

    public private(set) var activeGroups = Set<GroupID>() {
        didSet {
            guard oldValue != activeGroups else { return }
            log(.debug, "Active groups: \(activeGroups)")
            activeGroups.subtracting(oldValue).forEach { groupDidBecomeActive.send($0) }
            oldValue.subtracting(activeGroups).forEach { groupDidBecomeInactive.send($0) }
        }
    }

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
                self?.activeGroups = Set(value)
            }
    }

    func fetch(_ db: Database) throws -> [GroupID] {
        try GroupModel.fetchAll(db, isPending: false).map { $0.id }
    }
}

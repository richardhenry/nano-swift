//
//  RoleState.swift
//  NanoKit
//
//  Created by Richard Henry on 5/25/24.
//

import Combine
import Foundation
import GRDB
import NanoCore

public class RoleState {
    public static let shared = RoleState(dataStore: .shared)

    public let roleDidChange = PassthroughSubject<RoleModel, Never>()

    public private(set) var roles = [GroupID: RoleModel]() {
        didSet {
            guard oldValue != roles else { return }

            log(.debug, "Group roles: \(roles)")

            for (_, role) in oldValue where role != roles[role.id] {
                roleDidChange.send(role)
            }

            for (_, role) in roles where oldValue[role.id] == nil {
                roleDidChange.send(role)
            }
        }
    }

    private var dataStore: DataStore
    private var observationCancelled: AnyCancellable?

    public init(dataStore: DataStore) {
        self.dataStore = dataStore

        self.observationCancelled =
            ValueObservation
            .tracking(fetch)
            .publisher(in: dataStore.dbReader)
            .sink { completion in
                if case .failure(let error) = completion {
                    log(error)
                }
            } receiveValue: { [weak self] value in
                self?.roles = value.reduce(into: [GroupID: RoleModel]()) {
                    $0[$1.id] = $1
                }
            }
    }

    func fetch(_ db: Database) throws -> [RoleModel] {
        try RoleModel.fetchAll(db)
    }
}

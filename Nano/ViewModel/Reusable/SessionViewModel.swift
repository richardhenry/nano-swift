//
//  SessionViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/7/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class SessionViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value: SessionModel?

    func fetch(_ db: Database) throws -> SessionModel? {
        try SessionModel.fetchOne(db)
    }
}

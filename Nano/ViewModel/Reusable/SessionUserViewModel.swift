//
//  SessionUserViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/19/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class SessionUserViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value: UserModel?

    func fetch(_ db: Database) throws -> UserModel? {
        if let userId = try SessionModel.fetchOne(db)?.userId {
            return try UserModel.fetchOne(db, id: userId)
        } else {
            return nil
        }
    }
}

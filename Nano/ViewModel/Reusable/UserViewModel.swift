//
//  UserViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/7/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class UserViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value: UserModel?
    let userId: UserID

    init(userId: UserID) {
        self.userId = userId
    }

    func fetch(_ db: Database) throws -> UserModel? {
        try UserModel.fetchOne(db, id: userId)
    }
}

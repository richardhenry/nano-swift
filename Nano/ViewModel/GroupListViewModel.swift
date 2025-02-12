//
//  GroupListViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/9/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class GroupListViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value = [GroupModel]()
    var searchText = ""

    func fetch(_ db: Database) throws -> [GroupModel] {
        try GroupListQuery(searchText: searchText).fetch(db)
    }
}

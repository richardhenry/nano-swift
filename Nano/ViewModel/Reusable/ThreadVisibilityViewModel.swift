//
//  ThreadVisibilityViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/9/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class ThreadVisibilityViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value: ThreadVisibilityValue?
    var groupId: GroupID?
    var threadId: ThreadID?

    init(groupId: GroupID?, threadId: ThreadID?) {
        self.groupId = groupId
        self.threadId = threadId
    }

    func fetch(_ db: Database) throws -> ThreadVisibilityValue? {
        guard let groupId, let threadId else { return nil }

        return try ThreadSettingModel.fetchValue(
            db,
            groupId: groupId,
            threadId: threadId,
            settingType: .visibility,
            defaultValue: .default
        )
    }
}

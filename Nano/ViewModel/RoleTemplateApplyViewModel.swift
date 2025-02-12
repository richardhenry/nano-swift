//
//  RoleTemplateApplyViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/4/24.
//

import Foundation
import NanoKit

@Observable final class RoleTemplateApplyViewModel: FormViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var formPhase: FormPhase = .pending
    var groupId: GroupID

    init(groupId: GroupID) {
        self.groupId = groupId
    }

    func performSubmit() async throws {
        try await RoleTemplateApplyAllUseCase(groupId: groupId, dataStore: dataStore).run()
    }

    func shouldComplete() throws -> Bool { false }
}

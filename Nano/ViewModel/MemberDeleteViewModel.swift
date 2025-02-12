//
//  MemberDeleteViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/4/24.
//

import Foundation
import NanoKit

@Observable class MemberDeleteViewModel: FormViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var formPhase: FormPhase = .pending
    var groupId: GroupID
    var userId: UserID

    init(groupId: GroupID, userId: UserID) {
        self.groupId = groupId
        self.userId = userId
    }

    func performSubmit() async throws {
        try await MemberLeaveUseCase(groupId: groupId, userId: userId, dataStore: dataStore).run()
    }
}

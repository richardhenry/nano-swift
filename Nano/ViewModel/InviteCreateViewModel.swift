//
//  InviteCreateViewModel.swift
//  Nano
//
//  Created by Richard Henry on 1/16/24.
//

import Combine
import CryptoKit
import Foundation
import NanoCore
import NanoKit

@Observable final class InviteCreateViewModel: FormViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var formPhase: FormPhase = .pending
    var groupId: GroupID
    var lifetime = LifetimeOptions.sevenDays

    init(groupId: GroupID) {
        self.groupId = groupId
    }

    func performSubmit() async throws {
        try await InviteCreateUseCase(groupId: groupId, lifetimeDuration: lifetime.duration).run()
    }

    enum LifetimeOptions: CaseIterable, Identifiable {
        var id: Self { self }

        case forever
        case threeHundredSixtyFiveDays
        case thirtyDays
        case sevenDays
        case twentyFourHours
        case oneHour

        var duration: Timestamp? {
            switch self {
            case .forever:
                nil
            case .threeHundredSixtyFiveDays:
                Timestamp.days(365)
            case .thirtyDays:
                Timestamp.days(30)
            case .sevenDays:
                Timestamp.days(7)
            case .twentyFourHours:
                Timestamp.hours(24)
            case .oneHour:
                Timestamp.hour
            }
        }
    }
}

//
//  ServerErrorPayload.swift
//  Nano
//
//  Created by Richard Henry on 1/22/24.
//

import Combine
import Foundation
import NanoCore

public struct ServerErrorPayload: Codable {
    public var error: ServerError

    enum CodingKeys: String, CodingKey {
        case error = "e"
    }
}

extension ServerErrorPayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        log(error)

        switch error {
        case .unauthorized:
            try DataStore.shared.deleteAll()
        case .updateRequired:
            await MainActor.run {
                AppState.shared.isUpdateRequired = true
            }
        default:
            break
        }
    }
}

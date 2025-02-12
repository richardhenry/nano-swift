//
//  EpochBundlePayload.swift
//  NanoKit
//
//  Created by Richard Henry on 3/22/24.
//

import Foundation
import NanoCrypto

public struct EpochBundlePayload: Codable {
    public var epoch: EpochPayload
    public var ciphertext: LabyrinthPQHPKE.SealedBox?
    public var discontiguous: Bool?

    enum CodingKeys: String, CodingKey {
        case epoch = "e"
        case ciphertext = "c"
        case discontiguous = "o"
    }
}

extension EpochBundlePayload: ServerEventPayload {
    public func handle(eventType: ServerEventType) async throws {
        if ciphertext == nil {
            try await EpochDerivePreviousUseCase(epoch: epoch).run()
        } else {
            try await EpochDeriveNextUseCase(bundle: self).run()
        }
    }
}

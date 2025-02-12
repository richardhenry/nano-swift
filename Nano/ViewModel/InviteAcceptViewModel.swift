//
//  InviteAcceptViewModel.swift
//  Nano
//
//  Created by Richard Henry on 1/17/24.
//

import Combine
import CryptoKit
import Foundation
import NanoCore
import NanoCrypto
import NanoKit

@Observable final class InviteAcceptViewModel: FormViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var formPhase: FormPhase = .pending
    var input = ""

    func parseInput() throws -> (token: Data, secretKey: SymmetricKey) {
        let material: String
        if input.starts(with: InviteLinkUseCase.baseURL.absoluteString),
            let value = input.split(separator: "/").last, value.count == 89
        {
            material = String(value)
        } else if input.count == 88 || input.count == 89 {
            material = input
        } else {
            throw error("Invite token is not valid.")
        }

        let token = try CheckByteToken(string: String(material.prefix(44)))
        let secretKey = try CheckByteToken(string: String(material.suffix(44)))

        return (token.rawValue, secretKey.symmetricKey)
    }

    func performSubmit() async throws {
        let (token, secretKey) = try parseInput()
        try await InviteAcceptUseCase(token: token, secretKey: secretKey).run()
    }
}

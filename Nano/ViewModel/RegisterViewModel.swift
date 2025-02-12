//
//  RegisterViewModel.swift
//  Nano
//
//  Created by Richard Henry on 1/17/24.
//

import CryptoKit
import NanoCore
import NanoCrypto
import NanoKit
import SwiftUI

@Observable final class RegisterViewModel: FormViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var formPhase: FormPhase = .pending

    enum Step {
        case email
        case sentMagicLink
        case name
        case recoveryKey
        case waiting
    }

    var currentStep = Step.email
    var email = ""
    var token = ""
    var name = ""
    var challenge: RegisterValidatePayload.Challenge?
    var recoveryKey = ""

    func parseToken() throws -> CheckByteToken {
        try CheckByteToken(string: token.split(separator: "/").last ?? "")
    }

    func parseRecoveryKey() throws -> SymmetricKey? {
        guard !recoveryKey.isEmpty else { return nil }
        return try CheckByteToken(string: recoveryKey).symmetricKey
    }

    func performSubmit() async throws {
        switch currentStep {
        case .email:
            try await handleSend()
        case .sentMagicLink:
            try await handleValidate()
        case .name:
            try await handleNew()
        case .recoveryKey:
            try await handleExisting()
        case .waiting:
            if challenge != nil {
                try await handleExisting()
            } else {
                try await handleNew()
            }
        }
    }

    func shouldComplete() throws -> Bool {
        false
    }

    func reset() {
        guard currentStep != .email else { return }
        currentStep = .email
    }

    func handleSend() async throws {
        guard email.contains(where: { $0 == "@" }) else {
            throw error("Email does not contain an @ symbol.")
        }

        let payload = RegisterSendPayload(email: email.trimmingCharacters(in: .whitespaces))

        try await RegisterSendUseCase(payload: payload).run()

        await MainActor.run {
            currentStep = .sentMagicLink
        }
    }

    func handleValidate() async throws {
        let token = try parseToken()

        let payload = try await RegisterValidateUseCase(token: token).run()

        if let challenge = payload?.challenge {
            self.challenge = challenge
            try await handleExisting()
        } else {
            await MainActor.run {
                currentStep = .name
            }
        }
    }

    func handleNew() async throws {
        await MainActor.run {
            currentStep = .waiting
        }

        let token = try parseToken()

        let user = UserPayload(
            userId: UserID(),
            name: name,
            image: nil,
            timestamp: .now()
        )

        try await RegisterNewUseCase(token: token, user: user).run()
    }

    func handleExisting() async throws {
        guard let challenge else {
            throw error("Missing registration challenge.")
        }

        await MainActor.run {
            currentStep = .waiting
        }

        let token = try parseToken()
        let ephemeralRecoveryKey = try parseRecoveryKey()

        do {
            try await RegisterExistingUseCase(
                token: token,
                challenge: challenge,
                ephemeralRecoveryKey: ephemeralRecoveryKey
            )
            .run()
        } catch is RegisterExistingUseCase.RecoveryKeyRequiredError {
            await MainActor.run {
                currentStep = .recoveryKey
            }
        }
    }
}

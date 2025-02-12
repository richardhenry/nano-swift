//
//  RegisterSendUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/7/24.
//

import Foundation

public struct RegisterSendUseCase: UseCase {
    public var payload: RegisterSendPayload

    public init(payload: RegisterSendPayload) {
        self.payload = payload
    }

    public func run() async throws {
        _ = try await APIRequest(path: "register", method: .post, session: nil, payload: payload)
            .send()
    }
}

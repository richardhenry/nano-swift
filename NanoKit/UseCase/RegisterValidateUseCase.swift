//
//  RegisterValidateUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/7/24.
//

import Foundation
import NanoCrypto

public struct RegisterValidateUseCase: UseCase {
    public var token: CheckByteToken

    public init(token: CheckByteToken) {
        self.token = token
    }

    public func run() async throws -> RegisterValidatePayload? {
        try await APIRequest(
            path: "register/\(token.urlSafeBase64EncodedString)",
            method: .get,
            session: nil
        )
        .send(decoding: RegisterValidatePayload.self).value
    }
}

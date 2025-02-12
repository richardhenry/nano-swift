//
//  KeychainError.swift
//  NanoCrypto
//
//  Created by Richard Henry on 5/14/24.
//

import Foundation
import NanoCore

public class KeychainError: AnyError {
    public let code: OSStatus?

    public var doesNotExist: Bool {
        code == errSecItemNotFound
    }

    public init(
        _ code: OSStatus,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        #if DEBUG
        let callStackSymbols = Thread.callStackSymbols
        #else
        let callStackSymbols: [String] = []
        #endif

        self.code = code

        super
            .init(
                message: "Keychain Error: \(SecCopyErrorMessageString(code, nil)) (\(code))",
                file: file,
                function: function,
                line: line,
                callStackSymbols: callStackSymbols,
                logLevel: .error
            )
    }

    required init(
        message: DebugString,
        file: String,
        function: String,
        line: UInt,
        callStackSymbols: [String],
        logLevel: Logger.Level
    ) {
        self.code = nil

        super
            .init(
                message: message,
                file: file,
                function: function,
                line: line,
                callStackSymbols: callStackSymbols,
                logLevel: logLevel
            )
    }
}

//
//  LoggableError.swift
//  NanoCore
//
//  Created by Richard Henry on 5/14/24.
//

import Foundation

open class AnyError: Error, CustomStringConvertible, @unchecked Sendable {
    public let message: DebugString
    public let file: String
    public let function: String
    public let line: UInt
    public let callStackSymbols: [String]
    public let logLevel: Logger.Level

    public var description: String {
        message.description
    }

    public var sourceDescription: String {
        let scopeName = file.components(separatedBy: "/").last!.deletingPathExtension
        return "\(scopeName):\(line) \(function)"
    }

    public var callStackDescription: String? {
        guard !callStackSymbols.isEmpty else { return nil }
        return callStackSymbols.joined(separator: "\n")
    }

    public required init(
        message: DebugString,
        file: String,
        function: String,
        line: UInt,
        callStackSymbols: [String],
        logLevel: Logger.Level
    ) {
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.callStackSymbols = callStackSymbols
        self.logLevel = logLevel
    }
}

public func error<Error: AnyError>(
    _ message: DebugString,
    as: Error.Type = AnyError.self,
    logLevel: Logger.Level = .error,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
) -> Error {
    #if DEBUG
    let callStackSymbols = Thread.callStackSymbols
    #else
    let callStackSymbols: [String] = []
    #endif

    return Error(
        message: message,
        file: file,
        function: function,
        line: line,
        callStackSymbols: callStackSymbols,
        logLevel: logLevel
    )
}

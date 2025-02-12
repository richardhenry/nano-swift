//
//  Logger.swift
//  NanoCore
//
//  Created by Richard Henry on 1/5/24.
//

import Foundation
import Puppy

@inlinable
public func log(
    _ level: Logger.Level,
    _ message: @autoclosure () -> DebugString,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
) {
    guard level >= Logger.level else { return }

    Logger.shared.log(
        level: level,
        message: message().description,
        file: file,
        function: function,
        line: line
    )
}

@inlinable
public func log(
    _ error: Error,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
) {
    let level = (error as? AnyError)?.logLevel ?? .error
    guard level >= Logger.level else { return }

    var message: String
    if let source = (error as? AnyError)?.sourceDescription {
        message = "Captured error from \(source): \(error)"
    } else {
        message = "Captured error: \(error)"
    }

    if level == .error,
        let callStack = (error as? AnyError)?.callStackDescription
    {
        message += "\n\n" + callStack
    }

    Logger.shared.log(
        level: level,
        message: message,
        file: file,
        function: function,
        line: line
    )
}

public struct Logger {
    #if DEBUG
    public static let level: Level = .debug
    #else
    public static let level: Level = .debug
    #endif

    public enum Level: CaseIterable, Comparable, Equatable {
        case trace
        case debug
        case info
        case warning
        case error

        @inlinable
        var puppyLevel: LogLevel {
            switch self {
            case .trace:
                return .trace
            case .debug:
                return .debug
            case .info:
                return .info
            case .warning:
                return .error
            case .error:
                return .critical
            }
        }
    }

    @usableFromInline
    var puppy: Puppy

    public static let shared = Logger()

    public var directoryURL: URL {
        FileManager.default.appGroupContainerURL
            .appending(path: directoryName, directoryHint: .isDirectory)
    }

    public let directoryName = "Log"

    public init() {
        puppy = Puppy()

        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "unknown"

        let formatter = LogFormatter()

        #if DEBUG
        let consoleLogger = OSLogger(
            "\(bundleIdentifier).ConsoleLogger",
            logLevel: Self.level.puppyLevel,
            logFormat: formatter
        )
        puppy.add(consoleLogger)
        #endif

        let fileManager = FileManager.default

        do {
            let directoryURL = try fileManager.secureAppGroupDirectory(path: directoryName)
            let logURL = directoryURL.appendingPathComponent(
                "\(bundleIdentifier.replacingOccurrences(of: ".", with: "-")).log"
            )

            let rotationConfig = RotationConfig(
                suffixExtension: .numbering,
                maxFileSize: 10 * 1024 * 1024
            )

            let fileLogger = try FileRotationLogger(
                "\(bundleIdentifier).Logger",
                logLevel: Self.level.puppyLevel,
                logFormat: formatter,
                fileURL: logURL,
                fileProtectionType: .completeUntilFirstUserAuthentication,
                isExcludedFromBackup: true,
                rotationConfig: rotationConfig,
                flushMode: .always,
                writeMode: .assert
            )

            puppy.add(fileLogger)
        } catch {
            puppy.error("Failed to attach file logger with error: \(error)")
        }
    }

    @usableFromInline
    func log(level: Level, message: String, file: String, function: String, line: UInt) {
        puppy.logMessage(
            level.puppyLevel,
            message: message.description,
            tag: "",
            function: function,
            file: file,
            line: line
        )
    }

    struct LogFormatter: LogFormattable {
        private let dateFormat: DateFormatter

        init() {
            dateFormat = DateFormatter()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            dateFormat.timeZone = TimeZone(identifier: "UTC")
            dateFormat.locale = Locale(identifier: "en_US_POSIX")
        }

        func formatMessage(
            _ level: LogLevel,
            message: String,
            tag: String,
            function: String,
            file: String,
            line: UInt,
            swiftLogInfo: [String: String],
            label: String,
            date: Date,
            threadID: UInt64
        ) -> String {
            let date = dateFormatter(date, withFormatter: dateFormat)
            let scopeName = fileName(file).deletingPathExtension
            return "\(date) - \(level) - \(scopeName):\(line) \(function) - \(message)"
        }
    }
}

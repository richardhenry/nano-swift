//
//  DebugString.swift
//  NanoCore
//
//  Created by Richard Henry on 6/1/21.
//

import Foundation

/// A string convertible that won't cause the compiler to complain if you interpolate optional values.
///
/// Optionals will not be wrapped with "Optional(...)" in the log output, and `nil` values will appear as "(nil)".
///
/// ```
/// func log(message: DebugString) {
///    print(message)
/// }
///
/// let a: Int?
/// log(message: "value of a: \(a)")  // no compiler warning!
/// ```
///
/// You can also use the debug string to get a format string version of the string interpolation, which can be useful for aggregating log messages.
///
/// ```
/// let message: DebugString = "here is a number: \(num)"
/// message.formatString  // "here is a number: %@"
/// ```
public struct DebugString: CustomStringConvertible, ExpressibleByStringLiteral,
    ExpressibleByStringInterpolation, Sendable
{
    public let value: String

    /// A format string derived from the interpolated values. Useful for aggregating log messages.
    public let formatString: String

    @inlinable
    public var description: String {
        return self.value
    }

    public init(stringLiteral value: String) {
        self.value = value
        self.formatString = value
    }

    public init(stringInterpolation: StringInterpolation) {
        self.value = stringInterpolation.elements.joined()
        self.formatString = stringInterpolation.formatElements.joined()
    }

    public static func stringForInterpolation<T>(_ value: T?) -> String {
        if let data = value as? Data {
            return "(\(data.count) bytes: \(data.base64EncodedString()))"
        } else if let value = value {
            return String(describing: value)
        } else {
            return "(nil)"
        }
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        public typealias StringLiteralType = String

        public var elements: [String]
        public var formatElements: [String]

        public init(literalCapacity: Int, interpolationCount: Int) {
            self.elements = []
            self.formatElements = []
        }

        public mutating func appendLiteral(_ literal: String) {
            self.elements.append(literal)
            self.formatElements.append(literal)
        }

        public mutating func appendInterpolation<T>(_ value: T?) {
            self.elements.append(DebugString.stringForInterpolation(value))
            self.formatElements.append("%@")
        }
    }
}

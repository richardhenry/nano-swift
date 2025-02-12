//
//  Timestamp.swift
//  NanoCore
//
//  Created by Richard Henry on 1/2/24.
//

import Foundation

/// `Timestamp` is an `Int64` containing the number of milliseconds since the Unix epoch.
public typealias Timestamp = Int64

extension Timestamp {
    /// Creates a new timestamp initialized to the current time.
    @inlinable
    public static func now() -> Timestamp {
        Timestamp(Date().timeIntervalSince1970 * 1000)
    }

    /// One second in miliseconds.
    public static let second: Timestamp = 1_000

    /// One minute in milliseconds.
    public static let minute: Timestamp = 60_000

    /// One hour in milliseconds.
    public static let hour: Timestamp = 3_600_000

    /// One day in milliseconds.
    public static let day: Timestamp = hour * 24

    /// Returns the number of milliseconds.
    @inlinable
    public static func milliseconds(_ milliseconds: Int64) -> Timestamp {
        milliseconds
    }

    /// Returns the number of seconds in milliseconds.
    @inlinable
    public static func seconds(_ seconds: Int64) -> Timestamp {
        second * seconds
    }

    /// Returns the number of minutes in milliseconds.
    @inlinable
    public static func minutes(_ minutes: Int64) -> Timestamp {
        minute * minutes
    }

    /// Returns the number of hours in milliseconds.
    @inlinable
    public static func hours(_ hours: Int64) -> Timestamp {
        hour * hours
    }

    /// Returns the number of days in milliseconds.
    @inlinable
    public static func days(_ days: Int64) -> Timestamp {
        day * days
    }

    /// Convert the timestamp into an imprecise date.
    @inlinable
    public func toDateLosingPrecision() -> Date {
        Date(timeIntervalSince1970: TimeInterval(self) / 1000)
    }
}

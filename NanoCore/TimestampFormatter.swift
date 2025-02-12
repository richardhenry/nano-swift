//
//  TimestampFormatter.swift
//  NanoCore
//
//  Created by Richard Henry on 1/2/24.
//

import Foundation

public struct TimestampFormatter {
    public var timestamp: Timestamp
    public var currentTimestamp: Timestamp
    public var calendar: Calendar

    public init(
        _ timestamp: Timestamp,
        currentTimestamp: Timestamp? = nil,
        calendar: Calendar? = nil
    ) {
        self.timestamp = timestamp
        self.currentTimestamp = currentTimestamp ?? .now()
        self.calendar = calendar ?? .current
    }

    /// Returns a localized string that describes both the current calendar date and time of day. e.g. "Today at 2:57 PM" or "Mar 31, 2021 at 10:34 AM"
    public func calendarDateAndTimeOfDay() -> String {
        String(localized: "\(calendarDate()) at \(timeOfDay())")
    }

    /// Returns a localized string that describes the current calendar date. e.g. "Today" "Yesterday" "Thursday" "Mar 31" or "Mar 31, 2021"
    public func calendarDate() -> String {
        let date = timestamp.toDateLosingPrecision()

        let year = calendar.component(.year, from: date)
        let yearNow = calendar.component(.year, from: currentTimestamp.toDateLosingPrecision())

        let days = numberOfCalendarDays()

        if days == 0 {
            return String(localized: "Today")
        } else if days == 1 {
            return String(localized: "Yesterday")
        } else if days > 1 && days < 7 {
            dateFormatter.setLocalizedDateFormatFromTemplate("EEEE")
            return dateFormatter.string(from: date)
        } else if yearNow > year {
            dateFormatter.setLocalizedDateFormatFromTemplate("EEE',' MMM d yyyy")
            return dateFormatter.string(from: date)
        } else {
            dateFormatter.setLocalizedDateFormatFromTemplate("EEE',' MMM d")
            return dateFormatter.string(from: date)
        }
    }

    /// Returns a localized string that describes the time of day. e.g. "10:34 AM"
    public func timeOfDay() -> String {
        timeFormatter.string(from: timestamp.toDateLosingPrecision())
    }

    /**
     Returns the number of calendar days that have elapsed using the current calendar.

     For example, if `from` is 11:59 PM yesterday and `to` is 12:01 AM today, this function will return 1.

     If `from` is nil, this function will return the maximum integer value.
     */
    public static func numberOfCalendarDays(
        from: Timestamp?,
        to: Timestamp,
        calendar: Calendar? = nil
    ) -> Int {
        guard let from = from else { return .max }
        let calendar = calendar ?? .current
        let dayStart = calendar.startOfDay(for: from.toDateLosingPrecision())
        let dayStartNow = calendar.startOfDay(for: to.toDateLosingPrecision())
        return calendar.dateComponents([.day], from: dayStart, to: dayStartNow).day!
    }

    /**
     Returns the number of calendar days that have elapsed using the current calendar.

     For example, if `date` is 11:59 PM yesterday and `now` is 12:01 AM today, this function will return 1.
     */
    public func numberOfCalendarDays() -> Int {
        Self.numberOfCalendarDays(from: timestamp, to: currentTimestamp, calendar: calendar)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

//
//  CMTime+Formatted.swift
//  NanoKit
//
//  Created by Richard Henry on 2/9/24.
//

import Foundation

extension TimeInterval {
    /// Returns the time interval as a media duration, i.e. MM:SS or HH:MM:SS.
    public var formattedDuration: String {
        let totalSeconds = Int(rounded())
        let hours = totalSeconds / 3600
        let minutes = totalSeconds % 3600 / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}

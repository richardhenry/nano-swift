//
//  DateTimeText.swift
//  NanoKit
//
//  Created by Richard Henry on 2/1/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct DateTimeText: View {
    var timestamp: Timestamp

    init(_ timestamp: Timestamp) {
        self.timestamp = timestamp
    }

    var body: some View {
        Text(TimestampFormatter(timestamp).calendarDateAndTimeOfDay())
    }
}

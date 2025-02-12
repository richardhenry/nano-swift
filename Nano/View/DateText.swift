//
//  DateText.swift
//  NanoKit
//
//  Created by Richard Henry on 2/1/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct DateText: View {
    var timestamp: Timestamp

    init(_ timestamp: Timestamp) {
        self.timestamp = timestamp
    }

    var body: some View {
        Text(TimestampFormatter(timestamp).calendarDate())
    }
}

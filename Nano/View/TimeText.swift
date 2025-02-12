//
//  TimeText.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct TimeText: View {
    var timestamp: Timestamp

    init(_ timestamp: Timestamp) {
        self.timestamp = timestamp
    }

    var body: some View {
        Text(TimestampFormatter(timestamp).timeOfDay())
    }
}

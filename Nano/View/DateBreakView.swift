//
//  DateBreakView.swift
//  Nano
//
//  Created by Richard Henry on 5/30/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct DateBreakView: View {
    var timestamp: Timestamp

    var body: some View {
        VStack(alignment: .center) {
            DateText(timestamp)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(.ultraThickMaterial, in: Capsule())
        }
        .padding(.vertical, 5)
        .frame(minWidth: 0, maxWidth: .infinity)
    }
}

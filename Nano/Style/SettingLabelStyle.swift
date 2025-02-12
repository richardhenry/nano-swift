//
//  SettingLabelStyle.swift
//  Nano
//
//  Created by Richard Henry on 2/27/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct SettingLabelStyle: LabelStyle {
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = platformValue(
        iOS: 31,
        macOS: 24
    )

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 14) {
            configuration.icon
                .symbolVariant(.fill)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: iconSize, height: iconSize)
                .background(.tint, in: RoundedRectangle(cornerRadius: 8))
            configuration.title
        }
    }
}

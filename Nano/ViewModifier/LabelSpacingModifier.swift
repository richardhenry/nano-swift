//
//  LabelSpacingModifier.swift
//  Nano
//
//  Created by Richard Henry on 2/14/24.
//

import SwiftUI

struct LabelSpacingModifier: ViewModifier {
    var spacing: Double

    func body(content: Content) -> some View {
        content
            .labelStyle(LabelSpacingStyle(spacing: spacing))
    }
}

extension View {
    func labelSpacing(_ spacing: Double) -> some View {
        self.modifier(LabelSpacingModifier(spacing: spacing))
    }
}

struct LabelSpacingStyle: LabelStyle {
    var spacing: Double

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: spacing) {
            configuration.icon
            configuration.title
        }
    }
}

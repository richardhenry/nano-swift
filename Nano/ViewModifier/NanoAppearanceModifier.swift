//
//  NanoAppearanceModifier.swift
//  Nano
//
//  Created by Richard Henry on 5/28/24.
//

import SwiftUI

struct NanoAppearanceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fontDesign(.rounded)
    }
}

extension View {
    func nanoAppearance() -> some View {
        self.modifier(NanoAppearanceModifier())
    }
}

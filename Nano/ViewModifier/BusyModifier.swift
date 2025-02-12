//
//  BusyModifier.swift
//  Nano
//
//  Created by Richard Henry on 3/27/24.
//

import SwiftUI

struct BusyOverlayModifier: ViewModifier {
    @Binding var isPresented: Bool
    var busyText: LocalizedStringKey?

    func body(content: Content) -> some View {
        content
            #if os(iOS)
        .fullScreenCover(isPresented: $isPresented) {
            BusyView(busyText: busyText)
        }
            #elseif os(macOS)
        .sheet(isPresented: $isPresented) {
            BusyView(busyText: busyText)
        }
            #endif
    }
}

extension View {
    func busyOverlay(isPresented: Binding<Bool>, busyText: LocalizedStringKey?) -> some View {
        self.modifier(BusyOverlayModifier(isPresented: isPresented, busyText: busyText))
    }
}

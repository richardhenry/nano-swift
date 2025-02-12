//
//  View+DebugRedraw.swift
//  Nano
//
//  Created by Richard Henry on 5/18/24.
//

#if DEBUG
import SwiftUI

private let debugRedrawColors = [
    Color.purple,
    Color.blue,
    Color.green,
    Color.yellow,
    Color.orange,
    Color.red,
]

extension View {
    func debugRedraw() -> some View {
        self.background(debugRedrawColors.randomElement()!)
    }
}
#endif

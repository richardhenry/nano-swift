//
//  AccessoryModifier.swift
//  Nano
//
//  Created by Richard Henry on 4/13/24.
//

import SwiftUI

#if os(iOS)
import Nano_iOS
#endif

extension View {
    func keyboardAccessory(@ViewBuilder rootView: @escaping () -> some View) -> some View {
        #if os(iOS)
        modifier(AccessoryModifier(rootView: rootView))
        #elseif os(macOS)
        safeAreaInset(edge: .bottom, content: rootView)
        #endif
    }
}

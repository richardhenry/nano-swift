//
//  QuickLookPreviewModifier.swift
//  Nano
//
//  Created by Richard Henry on 2/15/24.
//

import SwiftUI

#if os(iOS)
import Nano_iOS
#elseif os(macOS)
import Nano_Mac
#endif

extension View {
    func quickLookPreview(
        _ selectedItem: Binding<URL?>,
        itemProvider: @escaping () -> [QuickLookPreviewItem]
    ) -> some View {
        self.modifier(
            QuickLookPreviewModifier(selectedItem: selectedItem, itemProvider: itemProvider)
        )
    }
}

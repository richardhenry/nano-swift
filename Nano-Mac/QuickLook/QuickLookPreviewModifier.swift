//
//  QuickLookCoordinator.swift
//  Nano-Mac
//
//  Created by Richard Henry on 2/15/24.
//

import AppKit
import QuickLookUI
import SwiftUI

public struct QuickLookPreviewModifier: ViewModifier {
    @Binding public var selectedItem: URL?
    public let itemProvider: () -> [QuickLookPreviewItem]

    @StateObject private var coordinator = QuickLookPanelCoordinator()

    public init(selectedItem: Binding<URL?>, itemProvider: @escaping () -> [QuickLookPreviewItem]) {
        _selectedItem = selectedItem
        self.itemProvider = itemProvider
    }

    public func body(content: Content) -> some View {
        content
            .onChange(of: selectedItem) { _, newValue in
                guard let newValue = newValue else { return }

                let items = itemProvider()

                if let index = items.firstIndex(where: { $0.previewItemURL == newValue }) {
                    coordinator.items = items
                    coordinator.openPanel(initialIndex: index)
                }

                selectedItem = nil
            }
    }
}

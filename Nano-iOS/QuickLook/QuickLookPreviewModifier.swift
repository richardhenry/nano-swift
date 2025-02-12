//
//  QuickLookPreviewModifier.swift
//  Nano-iOS
//
//  Created by Richard Henry on 2/15/24.
//

import QuickLook
import SwiftUI
import UIKit

public struct QuickLookPreviewModifier: ViewModifier {
    @Binding public var selectedItem: URL?
    public let itemProvider: () -> [QuickLookPreviewItem]

    @State private var isPresented = false

    public init(selectedItem: Binding<URL?>, itemProvider: @escaping () -> [QuickLookPreviewItem]) {
        _selectedItem = selectedItem
        self.itemProvider = itemProvider
    }

    public func body(content: Content) -> some View {
        content
            .onChange(of: selectedItem) { _, newValue in
                isPresented = newValue != nil
            }
            .onChange(of: isPresented) { oldValue, newValue in
                if oldValue, !newValue {
                    selectedItem = nil
                }
            }
            .fullScreenCover(isPresented: $isPresented) {
                QuickLookView(selectedItem: $selectedItem, itemProvider: itemProvider)
                    .ignoresSafeArea()
            }
    }
}

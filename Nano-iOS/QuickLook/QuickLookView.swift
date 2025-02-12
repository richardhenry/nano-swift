//
//  QuickLookView.swift
//  Nano-iOS
//
//  Created by Richard Henry on 4/13/24.
//

import QuickLook
import SwiftUI
import UIKit

public struct QuickLookView: UIViewControllerRepresentable {
    @Binding public var selectedItem: URL?
    public let itemProvider: () -> [QuickLookPreviewItem]

    public init(selectedItem: Binding<URL?>, itemProvider: @escaping () -> [QuickLookPreviewItem]) {
        _selectedItem = selectedItem
        self.itemProvider = itemProvider
    }

    public func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator

        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.clearSelection)
        )

        if UIDevice.current.userInterfaceIdiom == .pad {
            controller.navigationItem.leftBarButtonItem = doneButton
        } else {
            controller.navigationItem.rightBarButtonItem = doneButton
        }

        return UINavigationController(rootViewController: controller)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(view: self)
    }

    public func updateUIViewController(_ uiViewController: UINavigationController, context: Context)
    {
        context.coordinator.items = itemProvider()
        if let selectedItem = selectedItem,
            let index = context.coordinator.items.firstIndex(where: {
                $0.previewItemURL == selectedItem
            })
        {
            (uiViewController.viewControllers[0] as! QLPreviewController).currentPreviewItemIndex =
                index
        }
    }

    public class Coordinator: QLPreviewControllerDataSource {
        let view: QuickLookView
        var items = [QuickLookPreviewItem]()

        init(view: QuickLookView) {
            self.view = view
        }

        public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            items.count
        }

        public func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        )
            -> QLPreviewItem
        {
            items[index]
        }

        @objc func clearSelection() {
            view.selectedItem = nil
        }
    }
}

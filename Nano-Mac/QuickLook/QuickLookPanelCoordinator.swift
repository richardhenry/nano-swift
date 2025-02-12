//
//  QuickLookPanelCoordinator.swift
//  Nano-Mac
//
//  Created by Richard Henry on 4/13/24.
//

import QuickLookUI

public class QuickLookPanelCoordinator: ObservableObject, QLPreviewPanelDataSource {
    var items = [QuickLookPreviewItem]()

    public func openPanel(initialIndex: Int) {
        let panel = QLPreviewPanel.shared()
        panel?.center()
        panel?.dataSource = self
        panel?.currentPreviewItemIndex = initialIndex
        panel?.makeKeyAndOrderFront(self)
    }

    public func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        items.count
    }

    public func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        items[index]
    }
}

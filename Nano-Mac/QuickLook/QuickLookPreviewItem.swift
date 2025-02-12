//
//  QuickLookPreviewItem.swift
//  Nano-Mac
//
//  Created by Richard Henry on 4/13/24.
//

import QuickLookUI

public class QuickLookPreviewItem: NSObject, QLPreviewItem {
    public var previewItemURL: URL?
    public var previewItemTitle: String?

    public init(url: URL, title: String) {
        previewItemURL = url
        previewItemTitle = title
    }
}

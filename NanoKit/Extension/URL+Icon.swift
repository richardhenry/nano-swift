//
//  URL+Icon.swift
//  NanoKit
//
//  Created by Richard Henry on 2/9/24.
//

import NanoCore
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension URL {
    public func icon() throws -> PlatformImage {
        #if os(macOS)
        NSWorkspace.shared.icon(forFile: path())
        #else
        let controller = UIDocumentInteractionController(url: self)
        if let icon = controller.icons.last {
            return icon
        } else {
            throw error("No icon available for file with extension: \(basename.pathExtension)")
        }
        #endif
    }
}

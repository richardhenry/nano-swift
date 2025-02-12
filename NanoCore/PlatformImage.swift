//
//  PlatformImage.swift
//  NanoCore
//
//  Created by Richard Henry on 2/9/24.
//

import QuickLookThumbnailing
import SwiftUI

#if os(macOS)
public typealias PlatformImage = NSImage
#elseif os(iOS)
public typealias PlatformImage = UIImage
#endif

extension Image {
    @inlinable
    public init(platformImage: PlatformImage) {
        #if os(macOS)
        self.init(nsImage: platformImage)
        #else
        self.init(uiImage: platformImage)
        #endif
    }
}

extension QLThumbnailRepresentation {
    @inlinable
    public var platformImage: PlatformImage {
        #if os(macOS)
        nsImage
        #else
        uiImage
        #endif
    }
}

extension ImageRenderer {
    @MainActor @inlinable public var platformImage: PlatformImage? {
        #if os(macOS)
        nsImage
        #else
        uiImage
        #endif
    }
}

#if os(macOS)
extension NSImage: @unchecked Sendable {}
#endif

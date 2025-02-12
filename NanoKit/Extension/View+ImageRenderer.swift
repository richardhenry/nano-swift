//
//  View+ImageRenderer.swift
//  NanoKit
//
//  Created by Richard Henry on 2/21/24.
//

import NanoCore
import SwiftUI

extension View {
    @MainActor public func renderImage(scale: CGFloat) -> PlatformImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = scale
        return renderer.platformImage
    }
}

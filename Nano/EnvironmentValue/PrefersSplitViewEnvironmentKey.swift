//
//  PrefersSplitViewEnvironmentKey.swift
//  NanoKit
//
//  Created by Richard Henry on 1/28/24.
//

import NanoCore
import NanoKit
import SwiftUI

private struct PrefersSplitViewEnvironmentKey: EnvironmentKey {
    static var defaultValue: Bool = platformValue(iOS: false, macOS: true)
}

extension EnvironmentValues {
    var prefersSplitView: Bool {
        get { self[PrefersSplitViewEnvironmentKey.self] }
        set { self[PrefersSplitViewEnvironmentKey.self] = newValue }
    }
}

#if os(iOS)
extension PrefersSplitViewEnvironmentKey: UITraitBridgedEnvironmentKey {
    fileprivate static func read(from traitCollection: UITraitCollection) -> Bool {
        return traitCollection.userInterfaceIdiom == .pad
    }

    fileprivate static func write(to mutableTraits: inout UIMutableTraits, value: Bool) {}
}
#endif

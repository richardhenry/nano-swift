//
//  PlatformColor.swift
//  NanoCore
//
//  Created by Richard Henry on 4/16/24.
//

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

#if os(macOS)
public typealias PlatformColor = NSColor
#elseif os(iOS)
public typealias PlatformColor = UIColor
#endif

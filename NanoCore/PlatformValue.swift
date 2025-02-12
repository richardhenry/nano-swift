//
//  PlatformValue.swift
//  NanoCore
//
//  Created by Richard Henry on 1/2/24.
//

import Foundation

@inlinable
public func platformValue<T>(iOS iOSValue: T, macOS macOSValue: T) -> T {
    #if os(macOS)
    return macOSValue
    #else
    return iOSValue
    #endif
}

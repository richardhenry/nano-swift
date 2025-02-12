//
//  BackgroundWork.swift
//  NanoKit
//
//  Created by Richard Henry on 2/8/24.
//

import Foundation
import NanoCore

#if canImport(UIKit)
import UIKit
#endif

/// This is a wrapper around the UIKit Background Task API for ensuring that work is able to finish if the app moves into the background. On platforms where UIKit is not available, this class does nothing.
///
/// For more information: https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background/extending_your_app_s_background_execution_time
///
public final class BackgroundWork: @unchecked Sendable, CustomDebugStringConvertible {
    public let name: String

    #if canImport(UIKit)
    private var identifier: UIBackgroundTaskIdentifier!
    private let didEnd = ClaimableSync()

    public var debugDescription: String {
        "BackgroundWork(\(name), \(identifier.rawValue))"
    }
    #else
    public var debugDescription: String {
        "BackgroundWork(\(name))"
    }
    #endif

    /// Begins a new background task.
    ///
    /// - Parameters:
    ///   - name: The name of the background task. For debugging purposes, does not need to be unique.
    ///   - expirationHandler: This closure will be called by the system if you run out of time. You must clean up immediately. The `end()` method will be called automatically when this closure returns.
    ///
    public init(_ name: String, expirationHandler: @escaping () -> Void) {
        self.name = name

        #if canImport(UIKit)
        identifier = UIApplication.shared.beginBackgroundTask(withName: name) { [self] in
            log(.warning, "Expired: \(self)")
            expirationHandler()
            self.end()
        }

        log(.trace, "Began: \(self)")
        #endif
    }

    /// Ends the background task. You must call this method.
    public func end() {
        #if canImport(UIKit)
        guard didEnd.claim() else { return }
        UIApplication.shared.endBackgroundTask(identifier)
        log(.trace, "Ended: \(self)")
        #endif
    }
}

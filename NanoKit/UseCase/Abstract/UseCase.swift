//
//  UseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 3/27/24.
//

import Foundation
import NanoCore
import SwiftUI

public protocol UseCase {
    associatedtype Result
    func run() async throws -> Result
}

public protocol UseCaseErrorHandler {
    func handleError(_ error: Error) async throws
}

extension UseCase where Result == Void {
    public func detachedTask(
        priority: TaskPriority = .userInitiated,
        completion: ((Bool) -> Void)? = nil
    ) {
        Task.detached(priority: priority) {
            let success: Bool

            do {
                try await run()
                success = true
            } catch {
                log(error)
                success = false

                if let handler = self as? UseCaseErrorHandler {
                    do {
                        try await handler.handleError(error)
                    } catch {
                        log(.warning, "Error occurred during use case error handling.")
                        log(error)
                    }
                }
            }

            await MainActor.run {
                completion?(success)
            }
        }
    }
}

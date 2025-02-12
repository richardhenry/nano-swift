//
//  NSItemProvider+Async.swift
//  NanoKit
//
//  Created by Richard Henry on 2/15/24.
//

import CoreTransferable
import Foundation

extension NSItemProvider {
    public func loadTransferable<T: Transferable>(type transferableType: T.Type) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            _ = loadTransferable(type: transferableType) { result in
                switch result {
                case .success(let transferable):
                    continuation.resume(returning: transferable)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

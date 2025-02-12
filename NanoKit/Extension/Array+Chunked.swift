//
//  Array+Chunked.swift
//  NanoKit
//
//  Created by Richard Henry on 2/13/24.
//

import Foundation

extension Array {
    public func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size)
            .map {
                Array(self[$0..<Swift.min($0 + size, count)])
            }
    }
}

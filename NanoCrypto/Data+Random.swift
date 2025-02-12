//
//  Data+Random.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/19/24.
//

import Foundation

extension Data {
    /// Creates a new data buffer with the specified count of random bytes.
    public init(randomBytes count: Int) {
        self = .init(count: count)
        withUnsafeMutableBytes {
            $0.initializeWithRandomBytes(count: count)
        }
    }
}

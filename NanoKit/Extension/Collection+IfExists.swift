//
//  Collection+IfExists.swift
//  NanoKit
//
//  Created by Richard Henry on 2/21/24.
//

import Foundation

extension Collection {
    /// Returns the element at the given index if it exists, otherwise nil.
    public subscript(ifExists index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

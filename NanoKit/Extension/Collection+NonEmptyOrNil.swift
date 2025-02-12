//
//  Collection+NonEmptyOrNil.swift
//  NanoKit
//
//  Created by Richard Henry on 4/9/24.
//

import Foundation

extension Collection {
    func nonEmptyOrNil() -> Self? {
        if isEmpty {
            return nil
        } else {
            return self
        }
    }
}

//
//  String+PathExtension.swift
//  Nano
//
//  Created by Richard Henry on 1/5/24.
//

import Foundation

extension String {
    /// The path extension, if any, of the string as interpreted as a path.
    public var pathExtension: String {
        (self as NSString).pathExtension
    }

    /// A new string made by deleting the extension (if any, and only the last).
    public var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }
}

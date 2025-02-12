//
//  NSAttributedString+Whitespace.swift
//  Nano
//
//  Created by Richard Henry on 4/8/24.
//

import Foundation

extension NSAttributedString {
    func isEmptyAfterTrimmingCharacters(in set: CharacterSet) -> Bool {
        string.trimmingCharacters(in: set).isEmpty
    }

    func trimmingCharacters(in set: CharacterSet) -> NSAttributedString {
        let startIndex =
            string.firstIndex {
                !$0.unicodeScalars.allSatisfy(set.contains)
            } ?? string.startIndex

        let endIndex =
            string.lastIndex {
                !$0.unicodeScalars.allSatisfy(set.contains)
            }
            .map { string.index(after: $0) } ?? string.endIndex

        return attributedSubstring(from: NSRange(startIndex..<endIndex, in: string))
    }
}

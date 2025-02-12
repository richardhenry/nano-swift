//
//  NSAttributedString+LocationAttributeRange.swift
//  Nano
//
//  Created by Richard Henry on 4/10/24.
//

import Foundation

extension NSAttributedString {
    func longestEffectiveRangeOfAttribute(
        _ key: NSAttributedString.Key,
        at location: Int
    ) -> NSRange? {
        guard location > 0, location < length else {
            return nil
        }

        var effectiveRange = NSRange(location: NSNotFound, length: 0)

        let value = attribute(
            key,
            at: location,
            longestEffectiveRange: &effectiveRange,
            in: NSRange(location: 0, length: length)
        )

        guard value != nil,
            effectiveRange.location != NSNotFound,
            effectiveRange.length > 0
        else {
            return nil
        }

        return effectiveRange
    }
}

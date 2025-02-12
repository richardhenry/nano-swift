//
//  String+Emoji.swift
//  NanoKit
//
//  Created by Richard Henry on 2/21/24.
//

import Foundation

extension Character {
    /// Returns true if the character will render as a colored emoji on this device.
    public var isEmoji: Bool {
        var isEmoji = false

        for scalar in unicodeScalars {
            guard
                scalar.properties.isEmoji || scalar.properties.isVariationSelector
                    || scalar == "\u{20E3}"  // Combining Enclosing Keycap
                    || scalar.value == 8205
            else {  // Zero Width Joiner
                // Abort early when encountering the first non-emoji scalar.
                return false
            }

            // The above checks may be true because we have a possible emoji character, but not all characters have an emoji presentation.
            // We must continue to test scalars to see if one of them has an emoji presentation, or if the character contains the emoji variation selector in which case it will be rendered as an emoji.

            if scalar.properties.isEmojiPresentation || scalar.properties.isVariationSelector {
                isEmoji = true
            }
        }

        return isEmoji
    }
}

extension String {
    /// Returns true if the string contains only emoji characters ignoring spaces. A string that contains only spaces will return false.
    public var containsOnlyEmojiIgnoringSpaces: Bool {
        var containsEmoji = false

        for character in self {
            if character == " " {
                continue
            } else if character.isEmoji {
                containsEmoji = true
            } else {
                return false
            }
        }

        return containsEmoji
    }
}

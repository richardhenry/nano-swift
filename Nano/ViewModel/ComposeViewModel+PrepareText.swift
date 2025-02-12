//
//  ComposeViewModel+PrepareText.swift
//  Nano
//
//  Created by Richard Henry on 4/9/24.
//

import Foundation
import NanoCore
import NanoKit

#if os(iOS)
import Nano_iOS
#elseif os(macOS)
import Nano_Mac
#endif

extension ComposeViewModel {
    func prepareText() throws -> (text: String, mentions: [Mention]) {
        guard let coordinator = textCoordinator else {
            throw error("Text coordinator is not available.")
        }

        let attributedText = coordinator.attributedText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // Just use the NSString backing directly because we are working with NSRange.
        let string = attributedText.string as NSString

        var cursor = 0
        var encoded = ""
        var mentions = [Mention]()

        attributedText.enumerateAttribute(
            .customMention,
            in: NSRange(location: 0, length: attributedText.length)
        ) { value, range, _ in
            guard let mention = value as? Mention.Partial else { return }

            // Insert the prefix before the mention.
            let prefix = NSRange(location: cursor, length: range.lowerBound)
            encoded.append(string.substring(with: prefix))

            // Insert the mention placeholder and encoded mention info.
            encoded.append("@")
            mentions.append(mention.location(encoded.utf16.count))

            cursor = range.upperBound
        }

        if cursor < string.length {
            // Append the remaining text after the last mention.
            let suffix = NSRange(location: cursor, length: string.length)
            encoded.append(string.substring(with: suffix))
        }

        return (encoded, mentions)
    }
}

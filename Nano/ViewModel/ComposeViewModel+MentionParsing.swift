//
//  ComposeViewModel+MentionParsing.swift
//  Nano
//
//  Created by Richard Henry on 4/10/24.
//

import Foundation
import NanoKit

#if os(iOS)
import Nano_iOS
#elseif os(macOS)
import Nano_Mac
#endif

private let maxLookBackDistance = 51  // The maximum name length, plus an @ symbol.

extension ComposeViewModel {
    /// Returns the location of the last at symbol before the currently selected range.
    func locationOfLastAtSymbolBeforeSelection(_ coordinator: MessageTextViewCoordinator) -> Int? {
        let selectedRange = coordinator.selectedRange

        guard selectedRange.location > 0 else {
            return nil
        }

        let string = coordinator.attributedText.string

        let startLocation = max(0, selectedRange.location - maxLookBackDistance)

        var searchLocation = selectedRange.location
        var searchIndex = string.utf16.index(
            string.utf16.startIndex,
            offsetBy: selectedRange.location
        )

        guard searchLocation > startLocation else {
            return nil
        }

        while searchLocation > startLocation {
            searchLocation -= 1
            searchIndex = string.utf16.index(before: searchIndex)

            let character = string[searchIndex]

            if character.isNewline {
                return nil
            } else if character == "@" {
                return searchLocation
            }
        }

        return nil
    }

    func insertMention(user: UserModel) -> Bool {
        guard let coordinator = textCoordinator else {
            return false
        }

        guard let start = locationOfLastAtSymbolBeforeSelection(coordinator) else {
            return false
        }

        return coordinator.insertMentionText(
            "@\(user.name)",
            value: Mention.Partial(userId: user.id, name: user.name),
            startOffset: start
        )
    }
}

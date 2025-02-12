//
//  ComposeViewModel+MessageTextViewDelegate.swift
//  Nano
//
//  Created by Richard Henry on 3/6/24.
//

import Foundation
import NanoCore
import NanoKit

#if os(iOS)
import Nano_iOS
#elseif os(macOS)
import Nano_Mac
#endif

extension ComposeViewModel: MessageTextViewDelegate {
    func textView(
        _ coordinator: MessageTextViewCoordinator,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        if range.length > 0 && text == "",  // Handle backspace.
            let mentionRange = coordinator.attributedText.longestEffectiveRangeOfAttribute(
                .customMention,
                at: range.location
            ),
            range.location > mentionRange.location && range.location < mentionRange.upperBound
        {
            // Backspace immediately after a mention should first select the mention, then backspace again will delete it.
            coordinator.selectedRange = range
            return false

        } else if text.count > 7,  // At least "http://" before we try to match a URL.
            let request = LinkRequest(urlString: text),
            !links.contains(where: { $0.url == request.url })
        {
            // A URL was pasted. Add a link preview instead of allowing the paste.
            Task { await request.fetch() }
            links.append(LinkProvider(request: request))
            return false

        } else {
            return true
        }
    }

    func textViewDidChangeText(_ coordinator: MessageTextViewCoordinator) {
        // Look back to see if there is an unresolved mention in the last N characters and update the mention search text if needed.
        if let startIndex = locationOfLastAtSymbolBeforeSelection(coordinator).map({ $0 + 1 }),
            startIndex < coordinator.selectedRange.location,
            coordinator.attributedText.attribute(
                .customMention,
                at: startIndex,
                effectiveRange: nil
            )
                == nil
        {
            let searchRange = NSRange(
                location: startIndex,
                length: coordinator.selectedRange.location - startIndex
            )
            mentionPicker.searchText = (coordinator.attributedText.string as NSString)
                .substring(with: searchRange)
        } else {
            mentionPicker.searchText = ""
        }

        isTextEmpty = coordinator.attributedText.isEmptyAfterTrimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    func textView(
        _ coordinator: MessageTextViewCoordinator,
        targetSelectionRangeFor selectedRange: NSRange
    ) -> NSRange {
        // Ensure that a selection cannot partially intersect a mention. If it does, we want to expand the selection to fully include the mention.

        if let mentionRange = coordinator.attributedText.longestEffectiveRangeOfAttribute(
            .customMention,
            at: selectedRange.location
        ) {
            if selectedRange.length == 0,
                selectedRange.location > mentionRange.location,
                selectedRange.location < mentionRange.upperBound
            {
                return mentionRange
            } else if selectedRange.length > 0,
                selectedRange.location > mentionRange.location,
                selectedRange.location < mentionRange.upperBound
            {
                return NSRange(
                    location: mentionRange.location,
                    length: selectedRange.upperBound - mentionRange.location
                )
            }
        }

        if selectedRange.length > 0,
            let mentionRange = coordinator.attributedText.longestEffectiveRangeOfAttribute(
                .customMention,
                at: selectedRange.location
            ),
            selectedRange.upperBound > mentionRange.location,
            selectedRange.upperBound < mentionRange.upperBound
        {
            return NSRange(location: selectedRange.location, length: mentionRange.upperBound)
        }

        return selectedRange
    }

    func textViewDidPressReturnKey(_ coordinator: MessageTextViewCoordinator) {
        if !mentionPicker.acceptSelection() { submit() }
    }

    func textViewDidPressEscapeKey(_ coordinator: MessageTextViewCoordinator) {
        // TODO: Handle escape key.
    }

    func textViewShouldForwardArrowKeyPress(_ coordinator: MessageTextViewCoordinator) -> Bool {
        !mentionPicker.value.isEmpty
    }

    func textViewDidPressUpArrowKey(_ coordinator: MessageTextViewCoordinator) {
        mentionPicker.selectPrevious()
    }

    func textViewDidPressDownArrowKey(_ coordinator: MessageTextViewCoordinator) {
        mentionPicker.selectNext()
    }

    func textView(_ coordinator: MessageTextViewCoordinator, didPasteFile url: URL) {
        attachmentPicker.fileURLs.append(url)
    }

    func textView(_ coordinator: MessageTextViewCoordinator, didPasteImage image: PlatformImage) {
        attachmentPicker.asyncHandleImage(image)
    }
}

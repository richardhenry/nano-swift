//
//  MessageTextView.swift
//  Nano-iOS
//
//  Created by Richard Henry on 3/4/24.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

public protocol MessageTextViewDelegate: AnyObject {
    var textCoordinator: MessageTextViewCoordinator? { get set }
    func textView(
        _ coordinator: MessageTextViewCoordinator,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool
    func textViewDidChangeText(_ coordinator: MessageTextViewCoordinator)
    func textView(
        _ coordinator: MessageTextViewCoordinator,
        targetSelectionRangeFor selectedRange: NSRange
    ) -> NSRange
    func textViewDidPressReturnKey(_ coordinator: MessageTextViewCoordinator)
    func textViewDidPressEscapeKey(_ coordinator: MessageTextViewCoordinator)
    func textViewShouldForwardArrowKeyPress(_ coordinator: MessageTextViewCoordinator) -> Bool
    func textViewDidPressUpArrowKey(_ coordinator: MessageTextViewCoordinator)
    func textViewDidPressDownArrowKey(_ coordinator: MessageTextViewCoordinator)
    func textView(_ coordinator: MessageTextViewCoordinator, didPasteFile url: URL)
    func textView(_ coordinator: MessageTextViewCoordinator, didPasteImage image: UIImage)
}

public struct MessageTextView: UIViewRepresentable {
    @Binding public var isFocused: Bool
    public weak var delegate: MessageTextViewDelegate?

    public init(isFocused: Binding<Bool>, delegate: MessageTextViewDelegate) {
        _isFocused = isFocused
        self.delegate = delegate
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = TextView()
        textView.delegate = context.coordinator

        context.coordinator.textView = textView
        context.coordinator.delegate = delegate
        delegate?.textCoordinator = context.coordinator

        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = .label
        textView.backgroundColor = .clear
        textView.textContainer.heightTracksTextView = true
        textView.showsHorizontalScrollIndicator = false
        textView.isScrollEnabled = false

        textView.placeholderColor = .secondaryLabel
        textView.placeholderText = String(localized: "Say something…")

        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        if isFocused, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    public func makeCoordinator() -> MessageTextViewCoordinator {
        return MessageTextViewCoordinator(isFocused: $isFocused)
    }

    public func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UITextView,
        context: Context
    ) -> CGSize? {
        let bounds = CGSize(width: proposal.width ?? 300, height: .infinity)
        return CGSize(width: bounds.width, height: uiView.sizeThatFits(bounds).height)
    }
}

public final class MessageTextViewCoordinator: NSObject {
    @Binding public var isFocused: Bool
    public weak var delegate: MessageTextViewDelegate?
    var textView: TextView!

    public var attributedText: NSAttributedString {
        textView.attributedText
    }

    public var selectedRange: NSRange {
        get {
            textView.selectedRange
        }
        set {
            textView.selectedRange = newValue
        }
    }

    init(isFocused: Binding<Bool>) {
        _isFocused = isFocused
    }

    /// Inserts the provided text in the currently selected range.
    public func insertText(_ text: String) {
        let location = selectedRange.location

        if let selectedTextRange = textView.selectedTextRange {
            textView.replace(selectedTextRange, withText: text)
        } else {
            textView.insertText(text)
        }

        textView.selectedRange = NSRange(location: location, length: text.utf16.count)
    }

    /// Inserts a mention beginning at the `startOffset` and ending at the currently selected range.
    public func insertMentionText(
        _ mentionText: String,
        value mentionValue: Any,
        startOffset: Int
    ) -> Bool {
        guard selectedRange.location > startOffset,
            let start = textView.position(from: textView.beginningOfDocument, offset: startOffset),
            let end = textView.position(
                from: textView.beginningOfDocument,
                offset: selectedRange.location
            ),
            let insertionRange = textView.textRange(from: start, to: end)
        else {
            assertionFailure()
            return false
        }

        textView.replace(insertionRange, withText: mentionText)
        let mentionLength = (mentionText as NSString).length

        textView.selectedRange = NSRange(location: startOffset, length: mentionLength)
        textView.allowsEditingTextAttributes = true
        textView.updateTextAttributes { attributes in
            var attributes = attributes
            attributes[.customMention] = mentionValue
            attributes[.foregroundColor] = UIColor.tintColor
            return attributes
        }
        textView.allowsEditingTextAttributes = false

        textView.selectedRange = NSRange(location: startOffset + mentionLength, length: 0)

        return true
    }

    public func clearText() {
        textView.text = ""
        textView.handleTextChange()
    }
}

extension MessageTextViewCoordinator: UITextViewDelegate {
    public func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        delegate?.textView(self, shouldChangeTextIn: range, replacementText: text) != false
    }

    public func textViewDidChange(_ textView: UITextView) {
        if textView.typingAttributes[.customMention] != nil {
            textView.typingAttributes[.customMention] = nil
        }

        if (textView.typingAttributes[.foregroundColor] as? UIColor) != .label {
            textView.typingAttributes[.foregroundColor] = UIColor.label
        }

        delegate?.textViewDidChangeText(self)
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        guard let delegate = delegate else { return }

        let proposedRange = delegate.textView(self, targetSelectionRangeFor: textView.selectedRange)

        if proposedRange != textView.selectedRange {
            textView.selectedRange = proposedRange
        }
    }
}

extension MessageTextViewCoordinator: TextViewDelegate {
    func textViewDidBecomeFirstResponder(_ textView: TextView) {
        if !isFocused { isFocused = true }
    }

    func textViewDidResignFirstResponder(_ textView: TextView) {
        if isFocused { isFocused = false }
    }

    func textView(_ textView: TextView, didPasteImages images: [UIImage]) {
        for image in images {
            delegate?.textView(self, didPasteImage: image)
        }
    }

    func textViewDidPressReturnKey(_ textView: TextView) {
        delegate?.textViewDidPressReturnKey(self)
    }

    func textViewDidPressEscapeKey(_ textView: TextView) {
        delegate?.textViewDidPressEscapeKey(self)
    }
}

extension NSAttributedString.Key {
    public static let customMention = NSAttributedString.Key(rawValue: "customMention")
}

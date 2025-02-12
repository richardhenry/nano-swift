//
//  MessageTextView.swift
//  Nano-Mac
//
//  Created by Richard Henry on 4/9/24.
//

import AppKit
import SwiftUI

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
    func textView(_ coordinator: MessageTextViewCoordinator, didPasteImage image: NSImage)
}

public struct MessageTextView: NSViewRepresentable {
    @Binding public var isFocused: Bool
    public weak var delegate: MessageTextViewDelegate?

    public init(isFocused: Binding<Bool>, delegate: MessageTextViewDelegate?) {
        _isFocused = isFocused
        self.delegate = delegate
    }

    public func makeNSView(context: Context) -> NSTextView {
        let textView = TextView()
        textView.delegate = context.coordinator

        context.coordinator.textView = textView
        context.coordinator.delegate = delegate
        delegate?.textCoordinator = context.coordinator

        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.allowsUndo = true

        textView.placeholderText = NSAttributedString(
            string: String(localized: "Say something…"),
            attributes: [
                .foregroundColor: NSColor.secondaryLabelColor,
                .font: NSFont.preferredFont(forTextStyle: .body),
            ]
        )

        return textView
    }

    public func updateNSView(_ nsView: NSViewType, context: Context) {
        if let window = nsView.window {
            let isFirstResponder = window.firstResponder == nsView
            if isFocused, !isFirstResponder {
                nsView.becomeFirstResponder()
            } else if !isFocused, isFirstResponder {
                nsView.resignFirstResponder()
            }
        }
    }

    public func makeCoordinator() -> MessageTextViewCoordinator {
        MessageTextViewCoordinator(isFocused: $isFocused)
    }

    public func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: NSViewType,
        context: Context
    ) -> CGSize? {
        var size = CGSize(width: proposal.width ?? 300, height: .infinity)

        if let layoutManager = nsView.layoutManager, let textContainer = nsView.textContainer {
            layoutManager.ensureLayout(for: textContainer)
            size.height = layoutManager.usedRect(for: textContainer).height
        } else {
            size.height = 30
        }

        return size
    }
}

public final class MessageTextViewCoordinator: NSObject {
    @Binding public var isFocused: Bool
    public weak var delegate: MessageTextViewDelegate?
    var textView: TextView!
    private var shouldChangeTextEnabled = true

    public var attributedText: NSAttributedString {
        textView.attributedString()
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
        shouldChangeTextEnabled = false
        defer { shouldChangeTextEnabled = true }

        textView.insertText(text, replacementRange: textView.selectedRange())
    }

    /// Inserts a mention beginning at the `startOffset` and ending at the currently selected range.
    public func insertMentionText(
        _ mentionText: String,
        value mentionValue: Any,
        startOffset: Int
    ) -> Bool {
        shouldChangeTextEnabled = false
        defer { shouldChangeTextEnabled = true }

        let endOffset = textView.selectedRange().lowerBound
        guard endOffset > startOffset else {
            assertionFailure()
            return false
        }

        let replacementRange = NSRange(location: startOffset, length: endOffset)

        let insertionText = NSAttributedString(
            string: mentionText,
            attributes: [
                .customMention: mentionValue,
                .foregroundColor: NSColor.controlAccentColor,
            ]
        )

        textView.insertText(insertionText, replacementRange: replacementRange)

        return true
    }

    public func clearText() {
        shouldChangeTextEnabled = false
        defer { shouldChangeTextEnabled = true }

        textView.textStorage?.setAttributedString(NSAttributedString())
        textView.handleTextChange()
    }
}

extension MessageTextViewCoordinator: NSTextViewDelegate {
    public func textView(
        _ textView: NSTextView,
        shouldChangeTextIn affectedCharRange: NSRange,
        replacementString: String?
    ) -> Bool {
        if shouldChangeTextEnabled {
            return delegate?
                .textView(
                    self,
                    shouldChangeTextIn: affectedCharRange,
                    replacementText: replacementString ?? ""
                ) != false
        } else {
            return true
        }
    }

    public func textDidChange(_ notification: Notification) {
        if textView.typingAttributes[.customMention] != nil {
            textView.typingAttributes[.customMention] = nil
        }

        if (textView.typingAttributes[.foregroundColor] as? NSColor) != .labelColor {
            textView.typingAttributes[.foregroundColor] = NSColor.labelColor
        }

        textView.invalidateIntrinsicContentSize()

        delegate?.textViewDidChangeText(self)
    }

    public func textView(
        _ textView: NSTextView,
        willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange,
        toCharacterRange newSelectedCharRange: NSRange
    ) -> NSRange {
        delegate?.textView(self, targetSelectionRangeFor: newSelectedCharRange)
            ?? newSelectedCharRange
    }

    public func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if delegate?.textViewShouldForwardArrowKeyPress(self) == true {
            if commandSelector == #selector(NSStandardKeyBindingResponding.moveUp(_:)) {
                delegate?.textViewDidPressUpArrowKey(self)
                return true
            } else if commandSelector == #selector(NSStandardKeyBindingResponding.moveDown(_:)) {
                delegate?.textViewDidPressDownArrowKey(self)
                return true
            } else {
                return false
            }
        } else {
            return false
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

    func textView(_ textView: TextView, didPasteImages images: [NSImage]) {
        for image in images {
            delegate?.textView(self, didPasteImage: image)
        }
    }

    func textViewDidPressReturnKey(_ textView: TextView) {
        delegate?.textViewDidPressReturnKey(self)
    }
}

extension NSAttributedString.Key {
    public static let customMention = NSAttributedString.Key(rawValue: "customMention")
}

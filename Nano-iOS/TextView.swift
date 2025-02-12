//
//  TextView.swift
//  Nano-iOS
//
//  Created by Richard Henry on 3/4/24.
//

import UIKit
import UniformTypeIdentifiers

protocol TextViewDelegate: AnyObject {
    func textViewDidBecomeFirstResponder(_ textView: TextView)
    func textViewDidResignFirstResponder(_ textView: TextView)
    func textView(_ textView: TextView, didPasteImages images: [UIImage])
    func textViewDidPressReturnKey(_ textView: TextView)
    func textViewDidPressEscapeKey(_ textView: TextView)
}

class TextView: UITextView {
    var editingDelegate: TextViewDelegate? {
        delegate as? TextViewDelegate
    }

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(
                input: "\r",
                modifierFlags: .shift,
                action: #selector(alternateReturnKeyPressed)
            ),
            UIKeyCommand(
                input: "\r",
                modifierFlags: .alternate,
                action: #selector(alternateReturnKeyPressed)
            ),
            UIKeyCommand(action: #selector(returnKeyPressed), input: "\r"),
            UIKeyCommand(action: #selector(escapeKeyPressed), input: UIKeyCommand.inputEscape),
        ]
    }

    var placeholderText: String? {
        didSet {
            placeholderLabel.text = placeholderText
            accessibilityLabel = placeholderText
            setNeedsLayout()
        }
    }

    var placeholderColor: UIColor? {
        get {
            return placeholderLabel.textColor
        }
        set {
            placeholderLabel.textColor = newValue
        }
    }

    override var font: UIFont? {
        didSet {
            placeholderLabel.font = font
        }
    }

    let placeholderLabel = UILabel()

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        self.textContainer.lineFragmentPadding = 0

        adjustsFontForContentSizeCategory = true

        placeholderLabel.isAccessibilityElement = false
        placeholderLabel.adjustsFontForContentSizeCategory = true
        insertSubview(placeholderLabel, at: 0)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange(_:)),
            name: UITextView.textDidChangeNotification,
            object: self
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func becomeFirstResponder() -> Bool {
        if super.becomeFirstResponder() {
            editingDelegate?.textViewDidBecomeFirstResponder(self)
            return true
        } else {
            return false
        }
    }

    override func resignFirstResponder() -> Bool {
        if super.resignFirstResponder() {
            editingDelegate?.textViewDidResignFirstResponder(self)
            return true
        } else {
            return false
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        placeholderLabel.sizeToFit()
        placeholderLabel.frame.origin = CGPoint(
            x: textContainerInset.left,
            y: textContainerInset.top
        )
    }

    func handleTextChange() {
        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self)
        delegate?.textViewDidChange?(self)
    }

    @objc func textDidChange(_ notification: Notification) {
        placeholderLabel.isHidden = text.count != 0
    }

    @objc func returnKeyPressed(command: UIKeyCommand) {
        editingDelegate?.textViewDidPressReturnKey(self)
    }

    @objc func alternateReturnKeyPressed(command: UIKeyCommand) {
        insertText("\n")
        handleTextChange()
    }

    @objc func escapeKeyPressed(command: UIKeyCommand) {
        editingDelegate?.textViewDidPressEscapeKey(self)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) {
            return UIPasteboard.general.containsImagesIncludingHEIC
                || super.canPerformAction(action, withSender: sender)
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }

    override func paste(_ sender: Any?) {
        if let editingDelegate = editingDelegate,
            let images = UIPasteboard.general.imagesIncludingHEIC
        {
            editingDelegate.textView(self, didPasteImages: images)
        } else {
            super.paste(sender)
        }
    }
}

extension UIPasteboard {
    var containsImagesIncludingHEIC: Bool {
        contains(pasteboardTypes: [UTType.image.identifier])
    }

    var imagesIncludingHEIC: [UIImage]? {
        let images = data(forPasteboardType: UTType.image.identifier, inItemSet: nil)?
            .compactMap { UIImage(data: $0) }
        guard images?.isEmpty == false else { return nil }
        return images
    }
}

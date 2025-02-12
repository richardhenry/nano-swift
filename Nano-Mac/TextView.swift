//
//  TextView.swift
//  Nano-Mac
//
//  Created by Richard Henry on 3/7/24.
//

import AppKit

protocol TextViewDelegate: AnyObject {
    func textViewDidBecomeFirstResponder(_ textView: TextView)
    func textViewDidResignFirstResponder(_ textView: TextView)
    func textView(_ textView: TextView, didPasteImages images: [NSImage])
    func textViewDidPressReturnKey(_ textView: TextView)
}

class TextView: NSTextView {
    var editingDelegate: TextViewDelegate? {
        delegate as? TextViewDelegate
    }

    var placeholderText: NSAttributedString? {
        didSet {
            setAccessibilityLabel(placeholderText?.string)
            needsDisplay = true
        }
    }

    var modifierFlags: NSEvent.ModifierFlags?

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

    override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)
        textContainer?.lineFragmentPadding = 0
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if textStorage?.string.isEmpty != false {
            placeholderText?.draw(at: .zero)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)
        modifierFlags = event.modifierFlags
    }

    override func paste(_ sender: Any?) {
        guard !handlePaste(pasteboard: .general) else { return }
        super.pasteAsPlainText(sender)
    }

    override func insertNewline(_ sender: Any?) {
        if modifierFlags?.contains(.shift) == true || modifierFlags?.contains(.option) == true {
            super.insertNewline(sender)
        } else {
            editingDelegate?.textViewDidPressReturnKey(self)
        }
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        return handlePaste(pasteboard: pasteboard)
    }

    func handleTextChange() {
        NotificationCenter.default.post(name: NSTextView.didChangeNotification, object: self)
    }

    func handlePaste(pasteboard: NSPasteboard) -> Bool {
        if let images = pasteboard.images {
            editingDelegate?.textView(self, didPasteImages: images)
            return true
        } else {
            return false
        }
    }
}

extension NSPasteboard {
    var images: [NSImage]? {
        let images = readObjects(forClasses: [NSImage.classForCoder()])?
            .compactMap { $0 as? NSImage }
        guard images?.isEmpty == false else { return nil }
        return images
    }
}

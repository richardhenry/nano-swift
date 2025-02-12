//
//  AttachmentRequestView.swift
//  Nano
//
//  Created by Richard Henry on 5/28/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct AttachmentRequestView: View {
    var attachment: EncryptedAttachment
    var sizingMode: AttachmentView.SizingMode

    var body: some View {
        _Content(attachment: attachment, sizingMode: sizingMode).id(attachment.id)
    }

    struct _Content: View {
        @State private var request: AttachmentRequest
        var sizingMode: AttachmentView.SizingMode

        init(attachment: EncryptedAttachment, sizingMode: AttachmentView.SizingMode) {
            _request = State(wrappedValue: AttachmentRequest(attachment: attachment))
            self.sizingMode = sizingMode
        }

        var body: some View {
            AttachmentView(request: request, sizingMode: sizingMode)
        }
    }
}

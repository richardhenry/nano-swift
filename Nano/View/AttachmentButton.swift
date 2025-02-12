//
//  AttachmentButton.swift
//  Nano
//
//  Created by Richard Henry on 2/15/24.
//

import NanoKit
import SwiftUI

struct AttachmentButton: View {
    var request: AttachmentRequest
    var sizingMode: AttachmentView.SizingMode = .square
    @Binding var selectedItem: URL?

    var body: some View {
        Button {
            if case .value(let file) = request.content {
                selectedItem = file.url
            } else if case .failed = request.content {
                Task {
                    await request.fetch()
                }
            }
        } label: {
            AttachmentView(request: request, sizingMode: sizingMode)
        }
        .tint(.secondary)
        .buttonStyle(.borderless)
    }
}

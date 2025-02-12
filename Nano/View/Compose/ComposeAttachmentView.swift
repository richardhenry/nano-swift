//
//  ComposeAttachmentView.swift
//  Nano
//
//  Created by Richard Henry on 4/16/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct ComposeAttachmentView: View {
    static let size: CGFloat = platformValue(iOS: 88, macOS: 70)
    var attachment: LocalAttachment
    let removeAction: () -> Void

    var body: some View {
        LocalAttachmentView(attachment: attachment)
            .frame(width: Self.size, height: Self.size)
            .clipShape(RoundedRectangle(cornerRadius: platformValue(iOS: 12, macOS: 7)))
            .overlay(alignment: .bottomLeading) {
                if case .localFile(let value) = attachment.content,
                    let duration = (value as? SecureTemporaryMovieFile)?.duration
                {
                    Text(duration.formattedDuration)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .shadow(radius: 5)
                        .offset(x: 8, y: -6)
                }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    removeAction()
                } label: {
                    Label("Remove", systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                }
                .foregroundStyle(.primary, .regularMaterial)
                .environment(\.colorScheme, .dark)
                .buttonStyle(.borderless)
                .offset(x: -3, y: 3)
            }
            .task {
                await attachment.fetch()
            }
    }
}

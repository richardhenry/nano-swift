//
//  LocalAttachmentView.swift
//  Nano
//
//  Created by Richard Henry on 5/28/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct LocalAttachmentView: View {
    var attachment: LocalAttachment

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.quaternary)

            switch attachment.content {
            case .none, .loading:
                ProgressView()
            case .localFile(let value):
                switch value.thumbnail {
                case .fill(let image):
                    Image(platformImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                case .icon(let icon):
                    VStack {
                        Image(platformImage: icon)
                        Text(value.originalFilename)
                            .lineLimit(1)
                            .font(.caption)
                            .padding(.horizontal, 5)
                            .foregroundStyle(.secondary)
                    }
                }
            case .attachmentRequest(let request):
                AttachmentView(request: request, sizingMode: .square)
            case .publicImageRequest(let request):
                PublicImageView(request: request)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .font(.title)
        .imageScale(.large)
    }
}

//
//  AttachmentView.swift
//  Nano
//
//  Created by Richard Henry on 2/12/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct AttachmentView: View {
    enum SizingMode {
        case square
        case aspectRatio
    }

    var aspectRatio: CGFloat {
        if sizingMode == .aspectRatio, let size = request.attachment.size {
            return size.aspectRatio
        } else {
            return 1
        }
    }

    var request: AttachmentRequest
    var sizingMode: SizingMode = .square

    var body: some View {
        ZStack {
            Color.secondary.opacity(0.3)

            switch request.content {
            case .none, .loading:
                ProgressView()
            case .value(let value):
                switch value.thumbnail {
                case .fill(let image):
                    Image(platformImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .icon(let icon):
                    VStack {
                        Image(platformImage: icon)
                        Text(value.originalFilename)
                            .lineLimit(1)
                            .font(.caption)
                            .padding(.horizontal, 5)
                    }
                }
            case .failed:
                Image(systemName: "arrow.clockwise.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.title)
                    .imageScale(.large)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottomLeading) {
            if case .value(let value) = request.content,
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
        .clipShape(RoundedRectangle(cornerRadius: platformValue(iOS: 12, macOS: 7)))
    }
}

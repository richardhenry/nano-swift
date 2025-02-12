//
//  PublicImageView.swift
//  Nano
//
//  Created by Richard Henry on 5/30/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct PublicImageView: View {
    var request: PublicImageRequest

    var body: some View {
        ZStack {
            Color.secondary.opacity(0.3)

            switch request.content {
            case .none, .loading:
                ProgressView()
                    .controlSize(request.size == .small ? .small : .regular)
            case .value(let value):
                switch value.thumbnail {
                case .fill(let image):
                    Image(platformImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    EmptyView()
                }
            case .failed:
                EmptyView()
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: platformValue(iOS: 12, macOS: 7)))
    }
}

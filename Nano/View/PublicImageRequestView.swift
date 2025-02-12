//
//  PublicImageRequestView.swift
//  Nano
//
//  Created by Richard Henry on 5/30/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct PublicImageRequestView: View {
    var assetKey: String
    var size: PublicImageRequest.Size

    var body: some View {
        _Content(assetKey: assetKey, size: size).id(assetKey)
    }

    struct _Content: View {
        @State private var request: PublicImageRequest

        init(assetKey: String, size: PublicImageRequest.Size) {
            _request = State(wrappedValue: PublicImageRequest(assetKey: assetKey, size: size))
        }

        var body: some View {
            PublicImageView(request: request)
        }
    }
}

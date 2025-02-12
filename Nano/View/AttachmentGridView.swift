//
//  AttachmentGridView.swift
//  Nano
//
//  Created by Richard Henry on 2/12/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct AttachmentGridView: View {
    let gridSpacing: CGFloat = 5
    @State private var requests: [AttachmentRequest]
    @State private var numColumns: Int = 1
    @State private var selectedItem: URL?
    @ScaledMetric private var minColumnWidth: CGFloat = platformValue(iOS: 100, macOS: 230)
    @State private var unsizedItemSize: CGFloat = platformValue(iOS: 100, macOS: 230)

    init(attachments: [EncryptedAttachment]) {
        self.init(requests: attachments.map { AttachmentRequest(attachment: $0) })
    }

    init(requests: [AttachmentRequest]) {
        _requests = State(wrappedValue: requests)
    }

    var body: some View {
        Group {
            if requests.count == 1, let request = requests.first {
                let isUnsized = request.attachment.size == nil

                ZStack(alignment: .leading) {
                    Color.clear

                    AttachmentButton(
                        request: request,
                        sizingMode: .aspectRatio,
                        selectedItem: $selectedItem
                    )
                    .frame(
                        maxWidth: isUnsized ? unsizedItemSize : .infinity,
                        maxHeight: isUnsized ? unsizedItemSize : .infinity
                    )
                }
                .frame(minWidth: 0, maxWidth: .infinity)
            } else {
                let rows = requests.chunked(into: numColumns)

                Grid {
                    ForEach(0..<rows.count, id: \.self) { row in
                        GridRow {
                            ForEach(rows[row]) { request in
                                AttachmentButton(request: request, selectedItem: $selectedItem)
                            }
                        }
                    }
                }
                .id(requests.map { $0.id })
            }
        }
        .overlay {
            GeometryReader { geometry in
                Color.clear
                    .preference(key: AttachmentGridSize.self, value: geometry.size)
            }
        }
        .onPreferenceChange(AttachmentGridSize.self) { size in
            numColumns = max(Int(size.width / minColumnWidth), 1)
            unsizedItemSize =
                (size.width - gridSpacing * CGFloat(numColumns - 1)) / CGFloat(numColumns)
        }
        .quickLookPreview($selectedItem) {
            requests.compactMap { request in
                if case .value(let file) = request.content {
                    return .init(url: file.url, title: file.originalFilename)
                } else {
                    return nil
                }
            }
        }
    }
}

struct AttachmentGridSize: PreferenceKey {
    static var defaultValue = CGSize.zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

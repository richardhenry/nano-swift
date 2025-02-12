//
//  LinkProvider.swift
//  NanoKit
//
//  Created by Richard Henry on 2/15/24.
//

import SwiftUI

@Observable public class LinkProvider: Identifiable {
    public var id: URL {
        switch source {
        case .request(let request):
            return request.url
        case .preview(let preview):
            return preview.url
        }
    }

    public enum Source {
        case request(LinkRequest)
        case preview(LinkPreview)
    }

    public let source: Source
    public let imageRequest: AttachmentRequest?
    public let iconRequest: AttachmentRequest?

    public enum Style {
        case empty
        case compact
        case cover
        case microblog
    }

    public var style: Style {
        if summary != nil {
            return .microblog
        } else if image != nil {
            return .cover
        } else if title != nil {
            return .compact
        } else {
            return .empty
        }
    }

    public var isFetching: Bool {
        switch source {
        case .request(let request):
            return request.isFetching
        case .preview:
            return false
        }
    }

    public var url: URL {
        switch source {
        case .request(let request):
            request.url
        case .preview(let preview):
            preview.url
        }
    }

    public var domain: String {
        guard let host = url.host else {
            return String(localized: "(unknown)")
        }

        if host.hasPrefix("www."), host.split(separator: ".").count >= 3 {
            return String(host.dropFirst(4))
        } else {
            return host
        }
    }

    public var title: String? {
        switch source {
        case .request(let request):
            request.title
        case .preview(let preview):
            preview.title
        }
    }

    public var summary: String? {
        switch source {
        case .request(let request):
            request.summary
        case .preview(let preview):
            preview.summary
        }
    }

    public var hasImage: Bool {
        switch source {
        case .request(let request):
            return request.image != nil
        case .preview:
            return imageRequest != nil
        }
    }

    public var image: Image? {
        switch source {
        case .request(let request):
            return request.image?.thumbnail.fillImage
        case .preview:
            return imageRequest?.content?.thumbnail?.fillImage
        }
    }

    public var hasIcon: Bool {
        switch source {
        case .request(let request):
            return request.icon != nil
        case .preview:
            return iconRequest != nil
        }
    }

    public var icon: Image? {
        switch source {
        case .request(let request):
            return request.icon?.thumbnail.fillImage
        case .preview:
            return iconRequest?.content?.thumbnail?.fillImage
        }
    }

    public init(preview: LinkPreview) {
        source = .preview(preview)

        if let image = preview.image {
            imageRequest = AttachmentRequest(attachment: image)
        } else {
            imageRequest = nil
        }

        if let icon = preview.icon {
            iconRequest = AttachmentRequest(attachment: icon)
        } else {
            iconRequest = nil
        }
    }

    public init(request: LinkRequest) {
        source = .request(request)
        imageRequest = nil
        iconRequest = nil
    }
}

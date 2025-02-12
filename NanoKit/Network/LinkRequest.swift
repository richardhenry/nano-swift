//
//  LinkRequest.swift
//  NanoKit
//
//  Created by Richard Henry on 2/15/24.
//

import LinkPresentation
import NanoCore
import SwiftUI
import UniformTypeIdentifiers

@Observable public final class LinkRequest {
    public let url: URL
    public var isFetching = false
    public var title: String?
    public var summary: String?
    public var image: SecureTemporaryImageFile?
    public var icon: SecureTemporaryImageFile?

    public convenience init?(urlString: String) {
        guard let url = URL(string: urlString),
            url.host() != nil,
            url.scheme == "http" || url.scheme == "https"
        else {
            return nil
        }
        self.init(url: url)
    }

    public init(url: URL) {
        self.url = url
    }

    public func fetch() async {
        isFetching = true

        let metadata: LPLinkMetadata
        do {
            metadata = try await LPMetadataProvider().startFetchingMetadata(for: url)
        } catch {
            log(error)
            isFetching = false
            return
        }

        async let imageValue = metadata.imageProvider?
            .loadTransferable(
                type: SecureTemporaryImageFile.self
            )
        async let iconValue = metadata.iconProvider?
            .loadTransferable(
                type: SecureTemporaryImageFile.self
            )

        do {
            image = try await imageValue
        } catch {
            log(error)
        }

        do {
            icon = try await iconValue
        } catch {
            log(error)
        }

        title = metadata.title
        summary = metadata.summary
        isFetching = false
    }
}

extension LPLinkMetadata {
    fileprivate var summary: String? {
        let isX = url?.host == "twitter.com" || url?.host == "x.com"

        let isMastodon: Bool
        if let title = title {
            isMastodon = title.firstMatch(of: /^.+ \(\@.+\@.+\..+\)$/) != nil
        } else {
            isMastodon = false
        }

        if url?.host == "www.threads.net" || isX || isMastodon {
            let summary = value(forKey: "_summary") as? String

            if isX, let s = summary, s.first == "“", s.last == "”" {
                return String(s[s.index(after: s.startIndex)..<s.index(before: s.endIndex)])
            } else {
                return summary
            }
        } else {
            return nil
        }
    }
}

//
//  LocalAttachment.swift
//  NanoKit
//
//  Created by Richard Henry on 2/8/24.
//

import NanoCore
import PhotosUI
import SwiftUI

@Observable public final class LocalAttachment {
    enum Source {
        case photosPicker(PhotosPickerItem)
        case localFile(URL)
        case encryptedAttachment(EncryptedAttachment)
        case publicImage(assetKey: String)

        var photosPickerItem: PhotosPickerItem? {
            if case .photosPicker(let item) = self {
                return item
            } else {
                return nil
            }
        }

        var fileURL: URL? {
            if case .localFile(let url) = self {
                return url
            } else {
                return nil
            }
        }
    }

    public enum Content {
        case loading
        case failed(Error)
        case localFile(any SecureTemporaryFile)
        case attachmentRequest(AttachmentRequest)
        case publicImageRequest(PublicImageRequest)
    }

    let source: Source
    public var content: Content?

    public var isLoaded: Bool {
        switch content {
        case .none, .loading:
            return false
        case .localFile, .failed, .attachmentRequest, .publicImageRequest:
            return true
        }
    }

    public init(_ pickerItem: PhotosPickerItem) {
        source = .photosPicker(pickerItem)

        Task {
            await fetch()
        }
    }

    public init(_ fileURL: URL) {
        source = .localFile(fileURL)

        Task {
            await fetch()
        }
    }

    public init(_ remoteAttachment: EncryptedAttachment) {
        source = .encryptedAttachment(remoteAttachment)

        Task {
            await fetch()
        }
    }

    public init(publicImageAssetKey: String) {
        source = .publicImage(assetKey: publicImageAssetKey)

        Task {
            await fetch()
        }
    }

    public func fetch() async {
        switch content {
        case .none, .failed:
            content = .loading
        default:
            return
        }

        do {
            content = try await loadContent()
        } catch {
            log(error)
            content = .failed(error)
        }
    }

    private func loadContent() async throws -> Content {
        let result: Content

        switch source {
        case .photosPicker(let item):
            if let image = try await item.loadTransferable(type: SecureTemporaryImageFile.self) {
                result = .localFile(image)
            } else if let movie = try await item.loadTransferable(
                type: SecureTemporaryMovieFile.self
            ) {
                result = .localFile(movie)
            } else if let file = try await item.loadTransferable(
                type: SecureTemporaryAnyFile.self
            ) {
                result = .localFile(file)
            } else {
                throw error("Unable to load photos item.")
            }
        case .localFile(let url):
            let ownedDirectory = FileManager.default.secureTemporaryDirectoryURL
            if url.absoluteString.hasPrefix(ownedDirectory.absoluteString) {
                result = .localFile(
                    try await SecureTemporaryAnyFile.map(sourceURL: url)
                )
            } else {
                let scoped = url.startAccessingSecurityScopedResource()
                result = .localFile(
                    try await SecureTemporaryAnyFile.map(
                        sourceURL: url,
                        shouldCopyToRandomTemporaryFile: true
                    )
                )
                if scoped { url.stopAccessingSecurityScopedResource() }
            }
        case .encryptedAttachment(let attachment):
            let request = AttachmentRequest(attachment: attachment)
            result = .attachmentRequest(request)
        case .publicImage(let assetKey):
            let request = PublicImageRequest(assetKey: assetKey, size: .medium)
            result = .publicImageRequest(request)
        }

        return result
    }
}

extension LocalAttachment: Identifiable {
    public var id: String {
        switch source {
        case .photosPicker(let item):
            "0:\(item.itemIdentifier ?? ""):\(item.hashValue)"
        case .localFile(let url):
            "1:\(url)"
        case .encryptedAttachment(let attachment):
            "2:\(attachment.assetKey)"
        case .publicImage(let assetKey):
            "3:\(assetKey)"
        }
    }
}

extension LocalAttachment: Equatable {
    public static func == (lhs: LocalAttachment, rhs: LocalAttachment) -> Bool {
        lhs.id == rhs.id
    }
}

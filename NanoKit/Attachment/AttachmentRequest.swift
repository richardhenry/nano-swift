//
//  AttachmentRequest.swift
//  NanoKit
//
//  Created by Richard Henry on 2/12/24.
//

import Combine
import NanoCore
import NanoCrypto
import SwiftUI
import UniformTypeIdentifiers

@Observable public final class AttachmentRequest {
    public enum Content {
        case loading
        case failed(Error)
        case value(any SecureTemporaryFile)

        public var thumbnail: SecureTemporaryFileThumbnail? {
            if case .value(let file) = self {
                return file.thumbnail
            } else {
                return nil
            }
        }
    }

    public let attachment: EncryptedAttachment
    public private(set) var content: Content?

    public var isLoaded: Bool {
        switch content {
        case .none, .loading:
            return false
        case .value, .failed:
            return true
        }
    }

    public init(attachment: EncryptedAttachment) {
        self.attachment = attachment

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
            content = .value(try await loadContent())
        } catch {
            log(error)
            content = .failed(error)
        }
    }

    private func loadContent() async throws -> any SecureTemporaryFile {
        var cacheURL = try FileManager.default.secureTemporaryDirectory()
            .appending(component: attachment.assetKey, directoryHint: .notDirectory)

        if let utType = attachment.utType {
            cacheURL.appendPathExtension(for: utType)
        }

        if !FileManager.default.fileExists(atPath: cacheURL.path()) {
            var ciphertextURL = FileManager.default.appGroupContainerURL
                .appending(component: "PendingAttachment", directoryHint: .isDirectory)
                .appending(component: attachment.assetKey, directoryHint: .notDirectory)

            if !FileManager.default.fileExists(atPath: ciphertextURL.path()) {
                ciphertextURL = try await RemoteFile(
                    fileType: .attachment,
                    key: attachment.assetKey
                )
                .fetch()
            }

            let paddedURL = try FileManager.default.randomSecureTemporaryFile()

            try await XChaChaPolyFileStream()
                .decrypt(
                    source: ciphertextURL,
                    target: paddedURL,
                    key: attachment.encryptionKey.rawValue
                )

            try await PadmeFileStream().unpad(source: paddedURL, target: cacheURL)

            try? FileManager.default.removeItem(at: paddedURL)
        }

        return try await SecureTemporaryAnyFile.map(
            sourceURL: cacheURL,
            originalFilename: attachment.originalFilename,
            size: attachment.size ?? CGSize(width: 1000, height: 1000),
            duration: attachment.duration
        )
    }
}

extension AttachmentRequest: Identifiable {
    public var id: String {
        attachment.id
    }
}

extension AttachmentRequest: Equatable {
    public static func == (lhs: AttachmentRequest, rhs: AttachmentRequest) -> Bool {
        lhs.id == rhs.id
    }
}

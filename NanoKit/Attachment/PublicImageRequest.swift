//
//  PublicImageRequest.swift
//  Nano
//
//  Created by Richard Henry on 5/30/24.
//

import NanoCore
import SwiftUI

@Observable public final class PublicImageRequest {
    public static let requestFormat = "webp"
    public static let cacheFileExtension = "webp"

    public enum Size: Int {
        case small = 102
        case medium = 510

        var cgSize: CGSize {
            CGSize(width: rawValue, height: rawValue)
        }

        func cacheKey(forAssetKey assetKey: String) -> String {
            assetKey.deletingPathExtension + "@\(rawValue)w.\(cacheFileExtension)"
        }
    }

    public enum Content {
        case loading
        case failed(Error)
        case value(any SecureTemporaryFile)
    }

    public let assetKey: String
    public let size: Size
    public var content: Content?

    public var isLoaded: Bool {
        switch content {
        case .none, .loading:
            return false
        case .value, .failed:
            return true
        }
    }

    public init(assetKey: String, size: Size) {
        self.assetKey = assetKey
        self.size = size

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
            if size == .medium, let file = try await loadCached(size: .medium) {
                content = .value(file)
            } else if let file = try await loadCached(size: .small) {
                content = .value(file)

                if size == .medium {
                    do {
                        content = .value(try await loadRemote())
                    } catch {
                        log(error)
                    }
                }
            } else {
                content = .value(try await loadRemote())
            }
        } catch {
            log(error)
            content = .failed(error)
        }
    }

    private func cacheURL(cacheKey: String) throws -> URL {
        try FileManager.default.secureTemporaryDirectory()
            .appending(component: cacheKey, directoryHint: .notDirectory)
    }

    private func loadCached(size: Size) async throws -> (any SecureTemporaryFile)? {
        let cacheKey = size.cacheKey(forAssetKey: assetKey)
        let cacheURL = try cacheURL(cacheKey: cacheKey)

        if FileManager.default.fileExists(atPath: cacheURL.path) {
            return try await SecureTemporaryAnyFile.map(
                sourceURL: cacheURL,
                originalFilename: cacheKey,
                size: size.cgSize
            )
        } else {
            return nil
        }
    }

    private func loadRemote() async throws -> any SecureTemporaryFile {
        let cacheKey = size.cacheKey(forAssetKey: assetKey)
        var cacheURL = try cacheURL(cacheKey: cacheKey)

        guard let fileType = RemoteFileType(fileExtension: assetKey.pathExtension) else {
            throw error("Asset key does not include a valid file extension: \(assetKey)")
        }

        let temporaryURL = try await RemoteFile(
            fileType: fileType,
            key: assetKey,
            queryItems: [
                URLQueryItem(name: "w", value: String(size.rawValue)),
                URLQueryItem(name: "fm", value: Self.requestFormat),
            ]
        )
        .fetch()

        try? FileManager.default.copyItem(at: temporaryURL, to: cacheURL)
        try FileManager.default.makeSecure(&cacheURL)

        return try await SecureTemporaryAnyFile.map(
            sourceURL: cacheURL,
            originalFilename: cacheKey,
            size: size.cgSize
        )
    }
}

extension PublicImageRequest: Identifiable {
    public var id: String {
        assetKey
    }
}

extension PublicImageRequest: Equatable {
    public static func == (lhs: PublicImageRequest, rhs: PublicImageRequest) -> Bool {
        lhs.id == rhs.id
    }
}

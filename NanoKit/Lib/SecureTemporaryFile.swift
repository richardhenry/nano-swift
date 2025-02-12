//
//  SecureTemporaryFile.swift
//  NanoKit
//
//  Created by Richard Henry on 2/12/24.
//

import AVFoundation
import NanoCore
import NanoCrypto
import QuickLookThumbnailing
import SwiftUI

public enum SecureTemporaryFileThumbnail {
    case fill(PlatformImage)
    case icon(PlatformImage)

    public var fillImage: Image? {
        switch self {
        case .fill(let image):
            return Image(platformImage: image)
        case .icon:
            return nil
        }
    }
}

public protocol SecureTemporaryFile: Transferable, Equatable {
    var originalFilename: String { get }
    var url: URL { get }
    var contentType: UTType { get }
    var thumbnail: SecureTemporaryFileThumbnail { get }
}

public protocol SecureTemporaryMediaFile: SecureTemporaryFile {
    var size: CGSize { get }
}

extension SecureTemporaryFile {
    static func prepareFile(sourceURL: URL, shouldCopy: Bool) throws -> (URL, UTType) {
        let url: URL
        let contentType: UTType

        if shouldCopy {
            (url, contentType) = try Self.makeSecureCopy(sourceURL: sourceURL)
        } else {
            url = sourceURL
            contentType = try Self.getContentType(url: sourceURL)
        }

        return (url, contentType)
    }

    static func makeSecureCopy(sourceURL: URL) throws -> (url: URL, contentType: UTType) {
        let contentType = try getContentType(url: sourceURL)
        var targetURL = try FileManager.default.randomSecureTemporaryFile(contentType: contentType)
        try FileManager.default.copyItem(at: sourceURL, to: targetURL)
        try FileManager.default.makeSecure(&targetURL)
        return (targetURL, contentType)
    }

    static func getContentType(url: URL) throws -> UTType {
        if let contentType = try url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return contentType
        } else {
            throw error(
                "Missing content type for file with extension: \(url.basename.pathExtension)"
            )
        }
    }

    static func generateThumbnail(from url: URL) async throws -> PlatformImage {
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: 1000, height: 1000),
            scale: 1,
            representationTypes: .thumbnail
        )

        return try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            .platformImage
    }
}

public struct SecureTemporaryAnyFile: SecureTemporaryFile {
    public var originalFilename: String
    public var url: URL
    public var contentType: UTType
    public var thumbnail: SecureTemporaryFileThumbnail

    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .item) { file in
            SentTransferredFile(file.url)
        } importing: { receivedData in
            try await self.init(from: receivedData.file, shouldCopy: true)
        }
    }

    public static func map(
        sourceURL: URL,
        originalFilename: String? = nil,
        size: CGSize? = nil,
        duration: TimeInterval? = nil,
        shouldCopyToRandomTemporaryFile shouldCopy: Bool = false
    ) async throws -> any SecureTemporaryFile {
        guard
            let supertypes = try sourceURL.resourceValues(forKeys: [.contentTypeKey]).contentType?
                .supertypes
        else {
            throw error(
                "Content type not supported for file with extension: \(sourceURL.basename.pathExtension)"
            )
        }

        if supertypes.contains(.image) {
            return try await SecureTemporaryImageFile(
                from: sourceURL,
                originalFilename: originalFilename,
                size: size,
                shouldCopyToRandomTemporaryFile: shouldCopy
            )
        } else if supertypes.contains(.movie) {
            return try await SecureTemporaryMovieFile(
                from: sourceURL,
                originalFilename: originalFilename,
                size: size,
                shouldCopyToRandomTemporaryFile: shouldCopy
            )
        } else {
            return try await SecureTemporaryAnyFile(
                from: sourceURL,
                shouldCopy: shouldCopy,
                originalFilename: originalFilename
            )
        }
    }

    public init(from sourceURL: URL, shouldCopy: Bool, originalFilename: String? = nil) async throws
    {
        self.originalFilename = originalFilename ?? sourceURL.basename
        (url, contentType) = try Self.prepareFile(sourceURL: sourceURL, shouldCopy: shouldCopy)
        thumbnail = .icon(try url.icon())
    }

    public static func == (lhs: SecureTemporaryAnyFile, rhs: SecureTemporaryAnyFile) -> Bool {
        lhs.url == rhs.url
    }
}

public struct SecureTemporaryImageFile: SecureTemporaryFile, SecureTemporaryMediaFile {
    public var originalFilename: String
    public var url: URL
    public var contentType: UTType
    public var thumbnail: SecureTemporaryFileThumbnail
    public var size: CGSize

    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .image) { file in
            SentTransferredFile(file.url)
        } importing: { receivedData in
            try await self.init(from: receivedData.file, shouldCopyToRandomTemporaryFile: true)
        }
    }

    public static func getSize(from url: URL) throws -> CGSize {
        if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
            let width = props[kCGImagePropertyPixelWidth as String] as? Int,
            let height = props[kCGImagePropertyPixelHeight as String] as? Int
        {
            if let rawValue = props[kCGImagePropertyOrientation as String] as? UInt32,
                let orientation = CGImagePropertyOrientation(rawValue: rawValue),
                orientation.isRotated90Degrees
            {
                return CGSize(width: height, height: width)
            } else {
                return CGSize(width: width, height: height)
            }
        } else {
            throw error(
                "Unable to read image size from file with extension: \(url.basename.pathExtension)"
            )
        }
    }

    public init(
        from sourceURL: URL,
        originalFilename: String? = nil,
        size: CGSize? = nil,
        shouldCopyToRandomTemporaryFile shouldCopy: Bool = false
    ) async throws {
        self.originalFilename = originalFilename ?? sourceURL.basename
        (url, contentType) = try Self.prepareFile(sourceURL: sourceURL, shouldCopy: shouldCopy)
        thumbnail = .fill(try await Self.generateThumbnail(from: url))
        self.size = try size ?? Self.getSize(from: url)
    }

    public static func == (lhs: SecureTemporaryImageFile, rhs: SecureTemporaryImageFile) -> Bool {
        lhs.url == rhs.url
    }
}

public struct SecureTemporaryMovieFile: SecureTemporaryFile, SecureTemporaryMediaFile {
    public var originalFilename: String
    public var url: URL
    public var contentType: UTType
    public var thumbnail: SecureTemporaryFileThumbnail
    public var size: CGSize
    public var duration: TimeInterval?

    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { file in
            SentTransferredFile(file.url)
        } importing: { receivedData in
            try await self.init(from: receivedData.file, shouldCopyToRandomTemporaryFile: true)
        }
    }

    public init(
        from sourceURL: URL,
        originalFilename: String? = nil,
        size: CGSize? = nil,
        duration: TimeInterval? = nil,
        shouldCopyToRandomTemporaryFile shouldCopy: Bool = false
    ) async throws {
        self.originalFilename = originalFilename ?? sourceURL.basename
        (url, contentType) = try Self.prepareFile(sourceURL: sourceURL, shouldCopy: shouldCopy)
        thumbnail = .fill(try await Self.generateThumbnail(from: url))

        if let duration = duration, let size = size {
            self.size = size
            self.duration = duration
        } else {
            let asset = AVAsset(url: url)

            if let size = size {
                self.size = size
            } else {
                guard let track = try await asset.loadTracks(withMediaType: .video).first else {
                    throw error("Movie file has no video track.")
                }

                let naturalSize = try await track.load(.naturalSize)
                let preferredTransform = try await track.load(.preferredTransform)
                let adjustedSize = CGSizeApplyAffineTransform(naturalSize, preferredTransform)

                self.size = CGSize(width: abs(adjustedSize.width), height: abs(adjustedSize.height))
            }

            if let duration = duration {
                self.duration = duration
            } else {
                self.duration = CMTimeGetSeconds(try await asset.load(.duration))
            }
        }
    }

    public static func == (lhs: SecureTemporaryMovieFile, rhs: SecureTemporaryMovieFile) -> Bool {
        lhs.url == rhs.url
    }
}

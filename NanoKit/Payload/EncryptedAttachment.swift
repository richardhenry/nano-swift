//
//  EncryptedAttachment.swift
//  NanoKit
//
//  Created by Richard Henry on 2/12/24.
//

import CryptoKit
import Foundation
import GRDB
import NanoCrypto
import UniformTypeIdentifiers

public struct EncryptedAttachment: Codable, Equatable, Identifiable, DatabaseValueConvertible {
    public var id: String {
        assetKey
    }

    public var utType: UTType? {
        UTType(mimeType: mimeType)
    }

    public var localURL: URL {
        FileManager.default.appGroupContainerURL
            .appending(component: "PendingAttachment", directoryHint: .isDirectory)
            .appending(component: assetKey, directoryHint: .notDirectory)
    }

    public var assetKey: String
    public var originalFilename: String
    public var encryptionKey: InsecureCodableSymmetricKey
    public var mimeType: String
    public var size: CGSize?
    public var duration: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case assetKey = "k"
        case originalFilename = "f"
        case encryptionKey = "e"
        case mimeType = "m"
        case size = "s"
        case duration = "d"
    }

    public init(
        assetKey: String,
        originalFilename: String,
        encryptionKey: SymmetricKey,
        contentType: UTType,
        size: CGSize?,
        duration: TimeInterval?
    ) {
        self.assetKey = assetKey
        self.originalFilename = originalFilename
        self.encryptionKey = InsecureCodableSymmetricKey(rawValue: encryptionKey)
        self.mimeType = contentType.preferredMIMEType ?? "application/octet-stream"
        self.size = size
        self.duration = duration
    }

    public init(file: any SecureTemporaryFile) {
        let assetKey = file.url.basename.deletingPathExtension

        self.init(
            assetKey: assetKey,
            originalFilename: file.originalFilename,
            encryptionKey: SymmetricKey(size: .bits256),
            contentType: file.contentType,
            size: (file as? (any SecureTemporaryMediaFile))?.size,
            duration: (file as? SecureTemporaryMovieFile)?.duration
        )
    }

    public func encrypt(
        sourceFile file: any SecureTemporaryFile,
        intoDirectory localDirectory: URL
    ) async throws {
        let targetURL =
            localDirectory
            .appending(component: assetKey, directoryHint: .notDirectory)

        let paddedURL = try FileManager.default.randomSecureTemporaryFile()

        try await PadmeFileStream().pad(source: file.url, target: paddedURL)

        try await XChaChaPolyFileStream()
            .encrypt(
                source: paddedURL,
                target: targetURL,
                key: encryptionKey.rawValue
            )

        try? FileManager.default.removeItem(at: paddedURL)
    }
}

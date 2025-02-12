//
//  FileManager+Secure.swift
//  NanoKit
//
//  Created by Richard Henry on 3/20/24.
//

import Foundation
import NanoCore
import Security
import UniformTypeIdentifiers

extension FileManager {
    /// Returns an unused random file location in the secure temporary directory, without a file extension.
    public func randomSecureTemporaryFile() throws -> URL {
        try secureTemporaryDirectory().appendingPathComponent(randomFilename())
    }

    /// Returns an unused random file location in the secure temporary directory, using the file extension for the provided content type.
    public func randomSecureTemporaryFile(contentType: UTType) throws -> URL {
        try randomSecureTemporaryFile().appendingPathExtension(for: contentType)
    }

    /// Returns a cryptographically secure random filename with a length of 44 characters and no file extension.
    public func randomFilename() -> String {
        return Data(randomBytes: 33).urlSafeBase64EncodedString()
    }
}

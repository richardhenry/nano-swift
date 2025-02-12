//
//  FileManager+Secure.swift
//  NanoCore
//
//  Created by Richard Henry on 1/2/24.
//

import Foundation

extension FileManager {
    /// Turn on file system encryption and disable iCloud backups for the file at the provided URL.
    public func makeSecure(_ url: inout URL) throws {
        try setAttributes(
            [
                .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
            ],
            ofItemAtPath: url.path
        )

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }

    /// URL for the application group container.
    public var appGroupContainerURL: URL {
        containerURL(forSecurityApplicationGroupIdentifier: "group.nanochat.Nano")!
    }

    /// URL for the secure temporary directory.
    ///
    /// If you intend to write into the directory, you should use the `secureTemporaryDirectory()` method which will create the directory if it does not exist and make it secure.
    ///
    public var secureTemporaryDirectoryURL: URL {
        temporaryDirectory.appending(path: "Secure", directoryHint: .isDirectory)
    }

    /// Returns a URL to a secure subdirectory in the app group container.
    public func secureAppGroupDirectory(path: String) throws -> URL {
        var directoryURL =
            appGroupContainerURL
            .appending(path: path, directoryHint: .isDirectory)
        try createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try makeSecure(&directoryURL)
        return directoryURL
    }

    /// Returns a URL to a secure subdirectory in the current sandbox temporary directory.
    public func secureTemporaryDirectory() throws -> URL {
        var directoryURL = secureTemporaryDirectoryURL
        try createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try makeSecure(&directoryURL)
        return directoryURL
    }
}

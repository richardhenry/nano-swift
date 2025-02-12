//
//  RemoteFile.swift
//  NanoKit
//
//  Created by Richard Henry on 2/8/24.
//

import Foundation
import NanoCore

public struct RemoteFile {
    public let fileType: RemoteFileType
    public let key: String
    public var queryItems: [URLQueryItem]?

    public func remoteURL() throws -> URL {
        guard let host = fileType.remoteHost else {
            throw error("Remote file with type \(fileType) does not have a remote host.")
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/\(key)"
        if let queryItems {
            components.queryItems = queryItems
        }
        return try components.url ?! error("Failed to build remote URL.")
    }

    public func fetch() async throws -> URL {
        let url = try remoteURL()

        log(.info, "Fetching: \(url)")

        let (temporaryURL, response) = try await URLSession.shared.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw error("The server did not respond: \(response)")
        }

        guard httpResponse.statusCode == 200 else {
            throw error("The server responded with a non-200 status code: \(httpResponse)")
        }

        return temporaryURL
    }
}

public enum RemoteFileType: String, Sendable, CustomStringConvertible {
    case attachment
    case debug
    case publicWebP
    case publicHeic

    public var description: String {
        switch self {
        case .attachment:
            return "attachment"
        case .debug:
            return "debug"
        case .publicWebP:
            return "public-webp"
        case .publicHeic:
            return "public-heic"
        }
    }

    public var contentType: String {
        switch self {
        case .attachment:
            return "application/octet-stream"
        case .debug:
            return "application/zip"
        case .publicWebP:
            return "image/webp"
        case .publicHeic:
            return "image/heic"
        }
    }

    public var remoteHost: String? {
        switch self {
        case .attachment:
            return <#T##"attachment-cdn.example.com"##String#>
        case .debug:
            return nil
        case .publicWebP, .publicHeic:
            return <#T##"public-cdn.example.com"##String#>
        }
    }

    public init?(fileExtension: String) {
        switch fileExtension {
        case "heic":
            self = .publicHeic
        case "webp":
            self = .publicWebP
        default:
            return nil
        }
    }
}

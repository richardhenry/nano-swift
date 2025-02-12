//
//  Request.swift
//  Nano
//
//  Created by Richard Henry on 1/22/24.
//

import Foundation
import NanoCore

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public struct Request {
    public var urlRequest: URLRequest

    public static let baseURL: URL = {
        URL(string: <#T##"https://example.com/"##String#>)!
    }()

    public static let userAgent: String = {
        let bundleInfo = Bundle.main.infoDictionary!
        let version = bundleInfo["CFBundleShortVersionString"] as! String
        let buildNumber = bundleInfo["CFBundleVersion"] as! String

        let systemName = platformValue(iOS: "iOS", macOS: "macOS")
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
        let modelName = getDeviceModelName() ?? "unknown"

        return
            "Nano/\(version) (\(buildNumber)) \(systemName)/\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion) \(modelName)"
    }()

    public init(
        baseURL: URL = Request.baseURL,
        path: any StringProtocol,
        method: HTTPMethod,
        session: SessionModel?
    ) {
        urlRequest = URLRequest(url: Self.baseURL.appending(path: path))
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        if let session = session {
            urlRequest.setValue("Bearer \(session.token)", forHTTPHeaderField: "Authorization")
        }
    }
}

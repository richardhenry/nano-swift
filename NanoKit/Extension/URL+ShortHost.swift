//
//  URL+ShortHost.swift
//  NanoKit
//
//  Created by Richard Henry on 5/22/24.
//

import Foundation

extension URL {
    /// Returns the hostname without a "www." prefix. If no "www." prefix is present, the full hostname is returned.
    public var shortHost: String? {
        guard let host = host() else { return nil }

        if host.hasPrefix("www."), host.split(separator: ".").count >= 3 {
            return String(host.dropFirst(4))
        } else {
            return host
        }
    }
}

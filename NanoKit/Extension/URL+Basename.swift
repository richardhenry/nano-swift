//
//  URL+Basename.swift
//  Nano
//
//  Created by Richard Henry on 1/5/24.
//

import Foundation

extension URL {
    /// Extract the basename from the URL path, i.e. everything after the last / character.
    public var basename: String {
        path.pathBasename
    }
}

extension String {
    /// Treat this string as a URL path and extract the basename, i.e. everything after the last / character.
    public var pathBasename: String {
        if let slashIndex = lastIndex(where: { $0 == "/" }) {
            return String(self[index(after: slashIndex)...])
        }
        return self
    }
}

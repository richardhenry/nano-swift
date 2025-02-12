//
//  URL+StripTracking.swift
//  NanoKit
//
//  Created by Riley Patterson on 6/14/23.
//

import Foundation

extension URL {
    /// Modifies this URL in-place removing any known tracking parameters.
    public mutating func stripTracking() {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return
        }

        if let host = components.host {
            if host == "twitter.com" || host == "x.com" {
                if let queryItems = components.queryItems {
                    components.queryItems = queryItems.filter {
                        $0.name != "t" && $0.name != "s"
                    }
                }
            }

            if host.hasSuffix("instagram.com") || host.hasSuffix("threads.net") {
                if let queryItems = components.queryItems {
                    components.queryItems = queryItems.filter {
                        $0.name != "igshid"
                    }
                }
            }

            if host.hasSuffix("youtube.com") || host.hasSuffix("youtu.be") {
                if let queryItems = components.queryItems {
                    components.queryItems = queryItems.filter {
                        $0.name != "si"
                    }
                }
            }

            if host.hasSuffix("amazon.com") {
                if let queryItems = components.queryItems {
                    components.queryItems = queryItems.filter {
                        $0.name != "crid"
                            && $0.name != "qid"
                            && $0.name != "keywords"
                            && $0.name != "sprefix"
                            && $0.name != "sr"
                    }
                }
            }
        }

        if let queryItems = components.queryItems {
            components.queryItems = queryItems.filter {
                $0.name != "fbclid"
                    && $0.name != "mibextid"
                    && !$0.name.hasPrefix("utm_")
            }
        }

        if components.queryItems?.isEmpty == true {
            components.queryItems = nil
        }

        if let newValue = components.url {
            self = newValue
        }
    }
}

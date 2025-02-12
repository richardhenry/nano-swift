//
//  Data+URLSafeBase64.swift
//  Nano
//
//  Created by Richard Henry on 1/9/24.
//

import Foundation

extension Data {
    public enum Base64URLSafe {
        static let plus = "-"
        static let slash = "_"
    }

    public func urlSafeBase64EncodedString() -> String {
        self.base64EncodedString()
            .replacingOccurrences(of: "+", with: Base64URLSafe.plus)
            .replacingOccurrences(of: "/", with: Base64URLSafe.slash)
            .trimmingCharacters(in: ["="])
    }

    public init?(urlSafeBase64EncodedString string: any StringProtocol) {
        var string =
            string
            .replacingOccurrences(of: Base64URLSafe.plus, with: "+")
            .replacingOccurrences(of: Base64URLSafe.slash, with: "/")

        switch string.count % 4 {
        case 2:
            string += "=="
        case 3:
            string += "="
        default:
            break
        }

        self.init(base64Encoded: string)
    }
}

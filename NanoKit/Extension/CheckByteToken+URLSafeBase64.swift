//
//  CheckByteToken+URLSafeBase64.swift
//  NanoKit
//
//  Created by Richard Henry on 3/19/24.
//

import Foundation
import NanoCore
import NanoCrypto

extension CheckByteToken {
    public var urlSafeBase64EncodedString: String {
        combinedValue.urlSafeBase64EncodedString()
    }

    public init(string: any StringProtocol) throws {
        guard let data = Data(urlSafeBase64EncodedString: string) else {
            throw error("Unable to decode data from URL safe Base64.")
        }
        try self.init(combinedValue: data)
    }
}

//
//  PresignedUploadPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 2/8/24.
//

import Foundation
import NanoCore

struct PresignedUploadPayload: Decodable {
    var url: URL
    var key: String
    var contentType: String
    var expiresAt: Timestamp

    enum CodingKeys: String, CodingKey {
        case url = "u"
        case key = "k"
        case contentType = "m"
        case expiresAt = "e"
    }
}

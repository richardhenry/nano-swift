//
//  LinkPreview.swift
//  NanoKit
//
//  Created by Richard Henry on 2/15/24.
//

import Foundation

public struct LinkPreview {
    public var url: URL
    public var title: String?
    public var summary: String?
    public var image: EncryptedAttachment?
    public var icon: EncryptedAttachment?
}

extension LinkPreview: Codable {
    enum CodingKeys: String, CodingKey {
        case url = "u"
        case title = "t"
        case summary = "s"
        case image = "i"
        case icon = "c"
    }
}

extension LinkPreview: Identifiable {
    public var id: URL {
        url
    }
}

extension LinkPreview: Equatable {
    public nonisolated static func == (lhs: LinkPreview, rhs: LinkPreview) -> Bool {
        lhs.id == rhs.id
    }
}

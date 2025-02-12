//
//  UserModel.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

import Foundation
import GRDB

public struct UserModel: Identifiable, Hashable, Codable, FetchableRecord, PersistableRecord {
    public var id: UserID
    public var name: String
    public var image: String?

    public init(id: UserID, name: String, image: String?) {
        self.id = id
        self.name = name
        self.image = image
    }

    public static var databaseTableName = "user"

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name = "user_name"
        case image = "user_image"
    }

    public static func renderName(_ user: UserModel?) -> String {
        user?.name ?? String(localized: "Somebody")
    }
}

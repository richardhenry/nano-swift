//
//  EmojiSkinToneViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/8/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class EmojiSkinToneViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value: Int?

    func fetch(_ db: Database) throws -> Int? {
        try SecretSettingModel.fetchValue(db, settingType: .reactionSkinTone)
    }
}

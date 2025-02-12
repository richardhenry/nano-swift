//
//  ReactionPaletteViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/8/24.
//

import Foundation
import GRDB
import NanoKit

@Observable final class ReactionPaletteViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value = [ReactionPaletteItem]()
    var groupId: GroupID
    var targetId: MessageID

    init(groupId: GroupID, targetId: MessageID) {
        self.groupId = groupId
        self.targetId = targetId
    }

    func fetch(_ db: Database) throws -> [ReactionPaletteItem] {
        let defaultBases = ["❤️", "🔥", "😂", "😢", "👍"]

        let session = try SessionModel.fetchExpect(db)
        let skinToneVariation: Int? =
            try SecretSettingModel
            .fetchValue(db, settingType: .reactionSkinTone)

        let existing = try ReactionModel.fetchAll(
            db,
            groupId: groupId,
            targetId: targetId,
            userId: session.userId
        )

        let selection = Set(existing.compactMap { $0.base })

        return defaultBases.compactMap { base in
            guard let emoji = Emoji.lookup[base] else { return nil }

            var variation: String?
            if let skinToneVariation = skinToneVariation {
                variation = emoji.skinToneVariations[ifExists: skinToneVariation]
            }

            return ReactionPaletteItem(
                base: emoji.value,
                variation: variation,
                isSelected: selection.contains(base)
            )
        }
    }
}

struct ReactionPaletteItem: Identifiable {
    var id: String { base }
    var display: String { variation ?? base }
    var base: String
    var variation: String?
    var isSelected: Bool
}

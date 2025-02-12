//
//  GroupEditViewModel.swift
//  Nano
//
//  Created by Richard Henry on 1/30/24.
//

import CryptoKit
import NanoKit
import PhotosUI
import SwiftUI

@Observable final class GroupEditViewModel: FormViewModel, GroupEditFormViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var formPhase: FormPhase = .pending
    var groupId: GroupID
    var name: String
    var image: LocalAttachment? {
        didSet {
            if image == nil { photo = nil }
        }
    }
    var emoji: String? {
        didSet {
            if emoji != nil { photo = nil }
        }
    }
    var photo: PhotosPickerItem? {
        didSet {
            if let photo, oldValue != photo { image = LocalAttachment(photo) }
        }
    }

    init(group: GroupModel) {
        self.groupId = group.id
        self.name = group.name
        if let image = group.image {
            self.image = LocalAttachment(image)
        } else {
            self.image = nil
        }
        self.emoji = group.emoji
    }

    func performSubmit() async throws {
        try await GroupEditUseCase(
            groupId: groupId,
            name: name,
            image: image,
            emoji: emoji
        )
        .run()
    }
}

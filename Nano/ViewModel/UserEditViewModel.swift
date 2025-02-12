//
//  UserEditViewModel.swift
//  Nano
//
//  Created by Richard Henry on 5/29/24.
//

import NanoKit
import PhotosUI
import SwiftUI

@Observable final class UserEditViewModel: FormViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var formPhase: FormPhase = .pending
    var name = ""
    var image: LocalAttachment? {
        didSet {
            if image == nil { photo = nil }
        }
    }
    var photo: PhotosPickerItem? {
        didSet {
            if let photo, oldValue != photo { image = LocalAttachment(photo) }
        }
    }

    init(user: UserModel) {
        self.name = user.name
        if let image = user.image {
            self.image = LocalAttachment(publicImageAssetKey: image)
        } else {
            self.image = nil
        }
    }

    func performSubmit() async throws {
        try await UserEditUseCase(
            name: name,
            image: image
        )
        .run()
    }
}

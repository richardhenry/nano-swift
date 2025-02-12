//
//  GroupCreateViewModel.swift
//  Nano
//
//  Created by Richard Henry on 1/16/24.
//

import CryptoKit
import Foundation
import NanoKit
import PhotosUI
import SwiftUI

@Observable final class GroupCreateViewModel: FormViewModel, GroupEditFormViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var formPhase: FormPhase = .pending
    var name = ""
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

    func performSubmit() async throws {
        try await GroupCreateUseCase(
            name: name,
            image: image,
            emoji: emoji
        )
        .run()
    }
}

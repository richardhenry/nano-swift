//
//  SendFeedbackViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/19/24.
//

import Foundation
import NanoKit

@Observable final class SendFeedbackViewModel: FormViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var formPhase: FormPhase = .pending
    var userId: UserID?
    var text = ""
    var attachmentPicker = AttachmentPicker()

    func performSubmit() async throws {
        try await SendFeedbackUseCase(
            userId: userId,
            text: text,
            attachmentPicker: attachmentPicker
        )
        .run()
    }
}

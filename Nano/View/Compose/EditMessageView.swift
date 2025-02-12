//
//  EditMessageView.swift
//  Nano
//
//  Created by Richard Henry on 5/16/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct EditMessageView: View {
    @ViewModel private var viewer: ViewerRoleViewModel
    @ViewModel private var compose: ComposeViewModel
    @State private var isFocused = true
    @Environment(\.dismiss) private var dismiss

    init(existingMessage: MessageModel) {
        _viewer = ViewerRoleViewModel(groupId: existingMessage.groupId).wrapped()
        _compose = ComposeViewModel(existingMessage: existingMessage).wrapped()
    }

    var body: some View {
        let _ = Self._printChanges()

        ComposeSheetView(isFocused: $isFocused, compose: compose)
            .onChange(of: viewer.isMemberAllowed(.messageCreate), initial: true) {
                _,
                newValue in
                compose.isEnabled = newValue
            }
    }
}

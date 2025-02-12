//
//  NewThreadView.swift
//  Nano
//
//  Created by Richard Henry on 4/17/24.
//

import NanoKit
import SwiftUI

struct NewThreadView: View {
    let groupId: GroupID
    @ViewModel private var viewer: ViewerRoleViewModel
    @ViewModel private var compose: ComposeViewModel
    @State private var isFocused = true
    @Environment(\.dismiss) private var dismiss

    init(groupId: GroupID) {
        self.groupId = groupId
        _viewer = ViewerRoleViewModel(groupId: groupId).wrapped()
        _compose = ComposeViewModel(groupId: groupId, existingThreadId: nil).wrapped()
    }

    var body: some View {
        ComposeSheetView(isFocused: $isFocused, compose: compose)
            .onChange(of: viewer.isMemberAllowed(.threadCreate, .messageCreate), initial: true) {
                _,
                newValue in
                compose.isEnabled = newValue
            }
    }
}

//
//  MentionPickerView.swift
//  Nano
//
//  Created by Richard Henry on 4/10/24.
//

import NanoKit
import SwiftUI

struct MentionPickerView: View {
    @Bindable var mentionPicker: MentionPickerViewModel

    var body: some View {
        List(selection: $mentionPicker.selectedUserId) {
            ForEach(mentionPicker.value) { user in
                Button {
                    mentionPicker.selectedUserId = user.id
                    _ = mentionPicker.acceptSelection()
                } label: {
                    Text(UserModel.renderName(user))
                }
            }
        }
        .frame(maxWidth: 300, maxHeight: 300)
        .fixedSize()
        .background(.background)
    }
}

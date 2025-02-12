//
//  InviteAcceptView.swift
//  Nano
//
//  Created by Richard Henry on 1/17/24.
//

import NanoKit
import SwiftUI

struct InviteAcceptView: View {
    @ViewModel private var form = InviteAcceptViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Invite Link", text: $form.input)
            }
            .form(
                form,
                onCompletion: {
                    dismiss()
                }
            )
            .formToolbar(
                for: form,
                submitText: "Join",
                onCancel: {
                    dismiss()
                }
            )
            #if os(macOS)
            .frame(minWidth: 300)
            .padding(.all)
            #endif
            .navigationTitle("Join Group")
        }
    }
}

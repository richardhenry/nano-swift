//
//  RegisterPasteCodeView.swift
//  Nano
//
//  Created by Richard Henry on 1/14/24.
//

import NanoKit
import SwiftUI

struct RegisterPasteCodeView: View {
    @Bindable var model: RegisterViewModel
    @Binding var isPasteCodeVisible: Bool

    var body: some View {
        NavigationStack {
            Form {
                TextField("Code", text: $model.token)
                    .autocorrectionDisabled()
            }
            #if os(macOS)
            .frame(minWidth: 300)
            .padding(.all)
            #endif
            .navigationTitle("Paste Code")
            .formToolbar(
                for: model,
                submitText: "Submit",
                onCancel: {
                    isPasteCodeVisible = false
                }
            )
        }
        .disabled(model.formPhase.isDisabled)
        .onSubmit {
            model.submit()
        }
    }
}

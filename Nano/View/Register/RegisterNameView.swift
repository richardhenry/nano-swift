//
//  RegisterNameView.swift
//  Nano
//
//  Created by Richard Henry on 1/14/24.
//

import NanoKit
import SwiftUI

struct RegisterNameView: View {
    @Bindable var model: RegisterViewModel

    var body: some View {
        Form {
            TextField("Name", text: $model.name)
                .textContentType(.givenName)

            HStack {
                Button("Create Account") {
                    model.submit()
                }

                Spacer()

                LoadingView(model)
            }
        }
        .disabled(model.formPhase.isDisabled)
        .onSubmit {
            model.submit()
        }
        #if os(macOS)
        .frame(maxWidth: 300)
        .padding(.all)
        #endif
    }
}

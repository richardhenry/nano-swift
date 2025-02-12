//
//  RegisterEmailView.swift
//  Nano
//
//  Created by Richard Henry on 1/14/24.
//

import NanoKit
import SwiftUI

struct RegisterEmailView: View {
    @Bindable var model: RegisterViewModel

    var body: some View {
        Form {
            TextField("Email", text: $model.email)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                #if !os(macOS)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
                #endif

            HStack {
                Button("Send Magic Link") {
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

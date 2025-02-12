//
//  RegisterRecoveryView.swift
//  Nano
//
//  Created by Richard Henry on 4/26/24.
//

import NanoKit
import SwiftUI

struct RegisterRecoveryView: View {
    @Bindable var model: RegisterViewModel

    var body: some View {
        Form {
            TextField("Recovery Key", text: $model.recoveryKey)

            HStack {
                Button("Sign In") {
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

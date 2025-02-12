//
//  RegisterView.swift
//  Nano
//
//  Created by Richard Henry on 1/14/24.
//

import NanoKit
import SwiftUI

struct RegisterView: View {
    @ViewModel var model = RegisterViewModel()

    var body: some View {
        switch model.currentStep {
        case .email:
            RegisterEmailView(model: model)
        case .sentMagicLink:
            RegisterMagicLinkView(model: model)
        case .name:
            RegisterNameView(model: model)
        case .recoveryKey:
            RegisterRecoveryView(model: model)
        case .waiting:
            if model.formPhase.isError {
                RegisterErrorView(model: model)
            } else {
                ProgressView()
                    .controlSize(.extraLarge)
            }
        }
    }
}

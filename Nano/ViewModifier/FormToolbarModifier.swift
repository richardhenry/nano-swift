//
//  FormToolbarModifier.swift
//  Nano
//
//  Created by Richard Henry on 1/31/24.
//

import NanoKit
import SwiftUI

struct FormToolbarModifier<Model: FormViewModel>: ViewModifier {
    var model: Model
    var submitText: LocalizedStringKey
    var onCancel: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem {
                    LoadingView(model)
                }

                if let onCancel = onCancel {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            onCancel()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(submitText) {
                        model.submit()
                    }
                    .disabled(model.formPhase.isDisabled)
                }
            }
    }
}

extension View {
    func formToolbar<Model: FormViewModel>(
        for model: Model,
        submitText: LocalizedStringKey,
        onCancel: (() -> Void)?
    ) -> some View {
        self.modifier(FormToolbarModifier(model: model, submitText: submitText, onCancel: onCancel))
    }
}

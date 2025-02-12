//
//  FormViewModifier.swift
//  Nano
//
//  Created by Richard Henry on 1/31/24.
//

import NanoKit
import SwiftUI

struct FormViewModifier<Model>: ViewModifier where Model: FormViewModel {
    var model: Model
    var onCompletion: () -> Void

    func body(content: Content) -> some View {
        content
            .onSubmit {
                model.submit()
            }
            .disabled(model.formPhase.isDisabled)
            .onChange(of: model.formPhase) { oldValue, newValue in
                if oldValue != .complete, newValue == .complete {
                    onCompletion()
                }
            }
    }
}

extension View {
    func form<Model: FormViewModel>(
        _ model: Model,
        onCompletion: @escaping () -> Void
    )
        -> some View
    {
        self.modifier(FormViewModifier(model: model, onCompletion: onCompletion))
    }
}

//
//  RegisterMagicLinkView.swift
//  Nano
//
//  Created by Richard Henry on 1/14/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct RegisterMagicLinkView: View {
    var model: RegisterViewModel
    @State private var isPasteCodeVisible = false

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: "wand.and.stars")
                .font(.largeTitle)

            Text("Check Your Email")
                .fontWeight(.bold)

            Text("We sent a magic link to \(model.email) — tap the link to sign in.")
                .multilineTextAlignment(.center)

            Spacer().frame(height: 8)

            HStack(spacing: platformValue(iOS: 8, macOS: 5)) {
                Button("Go Back") {
                    model.reset()
                }
                .buttonStyle(.bordered)

                Button("Paste Code") {
                    isPasteCodeVisible = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .sheet(isPresented: $isPasteCodeVisible) {
            RegisterPasteCodeView(model: model, isPasteCodeVisible: $isPasteCodeVisible)
        }
    }
}

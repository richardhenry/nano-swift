//
//  LoadingView.swift
//  Nano
//
//  Created by Richard Henry on 4/7/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct LoadingView<Loader: Loadable>: View {
    var loader: Loader

    init(_ loader: Loader) {
        self.loader = loader
    }

    var body: some View {
        ZStack {
            ProgressView()
                .controlSize(platformValue(iOS: .regular, macOS: .small))
                .opacity(loader.loadingPhase == .loading ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: loader.loadingPhase)

            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
                .font(.body)
                .opacity(loader.loadingPhase == .error ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: loader.loadingPhase)
        }
    }
}

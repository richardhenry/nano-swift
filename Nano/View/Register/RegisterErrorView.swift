//
//  RegisterErrorView.swift
//  Nano
//
//  Created by Richard Henry on 1/16/24.
//

import NanoKit
import SwiftUI

struct RegisterErrorView: View {
    var model: RegisterViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: "exclamationmark.octagon")
                .font(.largeTitle)

            Text("Something Went Wrong")
                .fontWeight(.bold)

            Spacer().frame(height: 8)

            Button("Try Again") {
                model.submit()
            }
            .buttonStyle(.bordered)
        }
    }
}

//
//  ComposeSendButton.swift
//  Nano
//
//  Created by Richard Henry on 4/17/24.
//

import SwiftUI

struct ComposeSendButton: View {
    @Bindable var compose: ComposeViewModel

    var body: some View {
        Button {
            Task {
                compose.submit()
            }
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .resizable()
                .frame(
                    width: MessageView.userImageSize,
                    height: MessageView.userImageSize
                )
        }
        .accessibilityLabel("Send")
        .disabled(!compose.isSendEnabled)
    }
}

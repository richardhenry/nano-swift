//
//  RecoveryKeyView.swift
//  Nano
//
//  Created by Richard Henry on 4/26/24.
//

import NanoKit
import SwiftUI

struct RecoveryKeyView: View {
    @ViewModel private var recoveryKey = RecoveryKeyViewModel()

    var body: some View {
        Form {
            if let recoveryKey = recoveryKey.value?.urlSafeBase64EncodedString {
                HStack {
                    Text(recoveryKey)
                        .textSelection(.enabled)
                }
            } else {
                Text("Something went wrong.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Recovery Key")
        .toolbarTitleDisplayMode(.inline)
        .formStyle(.grouped)
    }
}

//
//  SessionWrapperView.swift
//  Nano
//
//  Created by Richard Henry on 1/14/24.
//

import Combine
import NanoKit
import SwiftUI

struct SessionWrapperView: View {
    @ViewModel private var session = SessionViewModel()
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            if session.value != nil {
                ContentView()
                    .onAppear {
                        notificationHandler.requestAuthorization()
                    }
            } else {
                RegisterView()
            }
        }
        .alert("Update Required", isPresented: $appState.isUpdateRequired) {
            Button("Open App Store", role: .cancel) {
                let url = URL(string: "https://apps.apple.com/us/app/nano-group-chat/id6476319990")!
                openURL(url)
            }
        } message: {
            Text("You need to update this app to continue using it.")
        }
    }
}

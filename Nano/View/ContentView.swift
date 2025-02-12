//
//  ContentView.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

import NanoKit
import SwiftUI

struct ContentView: View {
    @State private var navigationState = NavigationState()
    @Environment(\.prefersSplitView) private var prefersSplitView

    var body: some View {
        if prefersSplitView {
            NavigationSplitView(columnVisibility: $navigationState.columnVisibility) {
                GroupListView()
            } content: {
                GroupContentView()
            } detail: {
                ThreadContentView()
            }
            .navigationSplitViewStyle(.balanced)
            .environment(navigationState)
            #if os(macOS)
            .searchable(text: $navigationState.searchText)
            #endif
        } else {
            NavigationStack(path: $navigationState.navigationPath) {
                GroupListView()
                    .navigationDestination(for: GroupID.self) { groupId in
                        GroupContentView(groupId: groupId)
                    }
                    .navigationDestination(for: ThreadID.self) { threadId in
                        ThreadContentView(groupId: navigationState.groupId, threadId: threadId)
                    }
            }
            .environment(navigationState)
        }
    }
}

#Preview {
    ContentView()
        .environment(DataStore.preview())
}

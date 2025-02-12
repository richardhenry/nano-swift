//
//  EmptyTextView.swift
//  NanoKit
//
//  Created by Richard Henry on 1/31/24.
//

import NanoKit
import SwiftUI

struct EmptyTextView: View {
    let noItemsText: LocalizedStringKey
    let noSearchResultsText: LocalizedStringKey
    let isObservingSearch: Bool

    @Environment(\.isSearching) private var isSearching

    init(
        _ noItemsText: LocalizedStringKey,
        noSearchResults noSearchResultsText: LocalizedStringKey = "No Results",
        isObservingSearch: Bool = true
    ) {
        self.noItemsText = noItemsText
        self.noSearchResultsText = noSearchResultsText
        self.isObservingSearch = isObservingSearch
    }

    var body: some View {
        VStack {
            Spacer()
            Text(isSearching && isObservingSearch ? noSearchResultsText : noItemsText)
                .font(.title3)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

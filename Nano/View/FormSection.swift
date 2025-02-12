//
//  FormSection.swift
//  Nano
//
//  Created by Richard Henry on 2/4/24.
//

import SwiftUI

struct FormSection<Content: View>: View {
    let title: LocalizedStringKey?
    let helpText: LocalizedStringKey?
    let content: () -> Content

    init(
        _ title: LocalizedStringKey? = nil,
        helpText: LocalizedStringKey? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.helpText = helpText
        self.content = content
    }

    var body: some View {
        #if os(macOS)
        if let title = title, let helpText = helpText {
            Section(
                content: content,
                header: {
                    Text(title)
                    Text(helpText)
                }
            )
        } else if let title = title {
            Section(
                content: content,
                header: {
                    Text(title)
                }
            )
        } else {
            Section(content: content)
        }
        #else
        Section(content: content) {
            if let title = title {
                Text(title)
            }
        } footer: {
            if let helpText = helpText {
                Text(helpText)
            }
        }
        #endif
    }
}

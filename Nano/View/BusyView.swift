//
//  BusyView.swift
//  Nano
//
//  Created by Richard Henry on 3/27/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct BusyView: View {
    @Environment(\.dismiss) private var dismiss

    var busyText: LocalizedStringKey?

    var body: some View {
        #if os(iOS)
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            alertContent
                .shadow(radius: 100)
        }
        .ignoresSafeArea()
        .presentationBackground(.clear)
        #elseif os(macOS)
        alertContent
        #endif
    }

    @ViewBuilder var alertContent: some View {
        let size: CGFloat = platformValue(iOS: 180, macOS: 140)

        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)

            if let busyText = busyText {
                VStack(alignment: .center) {
                    Spacer()

                    Text(busyText)
                        .lineLimit(1)
                }
                .padding()
            }

            ProgressView()
                .controlSize(.extraLarge)
        }
        .frame(width: size, height: size)
    }
}

//
//  ScaleToFitModifier.swift
//  Nano
//
//  Created by Richard Henry on 5/28/24.
//

import SwiftUI

extension Text {
    func scaleTextToFit(fraction: CGFloat = 1) -> some View {
        GeometryReader { geometry in
            self
                .font(.system(size: 1000))
                .minimumScaleFactor(0.005)
                .lineLimit(1)
                .frame(
                    width: geometry.size.width * fraction,
                    height: geometry.size.height * fraction
                )
                .position(
                    x: geometry.frame(in: .local).midX,
                    y: geometry.frame(in: .local).midY
                )
        }
    }
}

extension Image {
    func scaleImageToFit(fraction: CGFloat = 1) -> some View {
        GeometryReader { geometry in
            self
                .resizable()
                .frame(
                    width: geometry.size.width * fraction,
                    height: geometry.size.height * fraction
                )
                .position(
                    x: geometry.frame(in: .local).midX,
                    y: geometry.frame(in: .local).midY
                )
        }
    }
}

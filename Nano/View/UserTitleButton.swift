//
//  UserTitleButton.swift
//  Nano
//
//  Created by Richard Henry on 4/19/24.
//

import NanoKit
import SwiftUI

struct UserTitleButton: View {
    var user: UserModel
    var action: (() -> Void)?
    var imageSize: CGFloat = 28

    var body: some View {
        if let action = action {
            Button(action: action) { content }.tint(.primary)
        } else {
            content
        }
    }

    @ViewBuilder var content: some View {
        HStack(spacing: 6) {
            UserImageView(user, size: .small)
                .frame(
                    idealWidth: imageSize,
                    maxWidth: imageSize,
                    idealHeight: imageSize,
                    maxHeight: imageSize
                )

            Text(UserModel.renderName(user))
                .fontWeight(.semibold)

            if action != nil {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 13))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary, Color.secondary.opacity(0.3))
            }
        }
    }
}

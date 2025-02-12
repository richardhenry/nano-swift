//
//  MemberItemView.swift
//  Nano
//
//  Created by Richard Henry on 5/30/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct MemberItemView: View {
    var groupId: GroupID
    var user: UserModel

    var body: some View {
        NavigationLink {
            MemberDetailView(groupId: groupId, userId: user.id)
        } label: {
            HStack(alignment: .center, spacing: 8) {
                userImage
                Text(UserModel.renderName(user))
            }
        }
    }

    @ViewBuilder var userImage: some View {
        let userImageSize: CGFloat = platformValue(iOS: 28, macOS: 24)

        UserImageView(user, size: .small)
            .frame(width: userImageSize, height: userImageSize)
    }
}

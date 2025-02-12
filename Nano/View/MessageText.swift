//
//  MessageText.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

import NanoKit
import SwiftUI

struct MessageText: View {
    var message: MessageModel
    var user: UserModel?

    var body: some View {
        if message.isDeleted {
            Text("\(UserModel.renderName(user)) deleted a message.")
        } else {
            Text(message.renderPlaintext(user: user))
        }
    }
}

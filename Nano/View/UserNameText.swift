//
//  UserNameText.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

import NanoKit
import SwiftUI

struct UserNameText: View {
    var user: UserModel?

    var body: some View {
        if let name = user?.name {
            Text(name)
        } else {
            Text("Somebody")
                .foregroundStyle(.secondary)
        }
    }
}

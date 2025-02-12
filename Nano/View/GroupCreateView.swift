//
//  GroupCreateView.swift
//  Nano
//
//  Created by Richard Henry on 1/6/24.
//

import NanoKit
import SwiftUI

struct GroupCreateView: View {
    @ViewModel private var form = GroupCreateViewModel()

    var body: some View {
        GroupEditFormView(
            form: form,
            titleText: "New Group",
            submitText: "Create"
        )
    }
}

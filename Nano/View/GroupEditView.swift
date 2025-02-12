//
//  GroupEditView.swift
//  Nano
//
//  Created by Richard Henry on 1/30/24.
//

import NanoKit
import SwiftUI

struct GroupEditView: View {
    @ViewModel private var form: GroupEditViewModel

    init(group: GroupModel) {
        _form = GroupEditViewModel(group: group).wrapped()
    }

    var body: some View {
        GroupEditFormView(
            form: form,
            titleText: "Edit Group",
            submitText: "Save"
        )
    }
}

//
//  InviteCreateView.swift
//  Nano
//
//  Created by Richard Henry on 1/16/24.
//

import Combine
import NanoKit
import SwiftUI

struct InviteCreateView: View {
    var groupId: GroupID
    @ViewModel private var model: InviteCreateViewModel
    @Environment(\.dismiss) private var dismiss

    init(groupId: GroupID) {
        self.groupId = groupId
        _model = InviteCreateViewModel(groupId: groupId).wrapped()
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Expires after…", selection: $model.lifetime) {
                    ForEach(InviteCreateViewModel.LifetimeOptions.allCases) {
                        $0.localizedText
                    }
                }
            }
            .form(
                model,
                onCompletion: {
                    dismiss()
                }
            )
            .formToolbar(
                for: model,
                submitText: "Create",
                onCancel: {
                    dismiss()
                }
            )
            #if os(macOS)
            .frame(minWidth: 300)
            .padding(.all)
            #endif
            .navigationTitle("New Invite Link")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

extension InviteCreateViewModel.LifetimeOptions {
    var localizedText: Text {
        switch self {
        case .forever:
            Text("Never")
        case .threeHundredSixtyFiveDays:
            Text("365 Days")
        case .thirtyDays:
            Text("30 Days")
        case .sevenDays:
            Text("7 Days")
        case .twentyFourHours:
            Text("24 Hours")
        case .oneHour:
            Text("1 Hour")
        }
    }
}

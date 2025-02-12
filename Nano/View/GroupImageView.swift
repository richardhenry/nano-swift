//
//  GroupImageView.swift
//  Nano
//
//  Created by Richard Henry on 5/28/24.
//

import NanoKit
import SwiftUI

struct GroupImageView: View {
    enum Source {
        case group(GroupModel?)
        case viewModel(any GroupEditFormViewModel)
        case fixedValue(Value)
    }

    enum Value: Equatable {
        case remoteImage(EncryptedAttachment)
        case localImage(LocalAttachment)
        case emoji(String)
        case initials(String)
        case add
    }

    var source: Source

    var value: Value {
        switch source {
        case .group(let group):
            if let image = group?.image {
                return .remoteImage(image)
            } else if let emoji = group?.emoji {
                return .emoji(emoji)
            } else if let initial = group?.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .first
            {
                return .initials(String(initial).uppercased())
            } else {
                return .initials("")
            }
        case .viewModel(let model):
            if let image = model.image {
                return .localImage(image)
            } else if let emoji = model.emoji {
                return .emoji(emoji)
            } else if let initial = model.name.trimmingCharacters(in: .whitespacesAndNewlines).first
            {
                return .initials(String(initial).uppercased())
            } else {
                return .add
            }
        case .fixedValue(let value):
            return value
        }
    }

    init(_ value: Value) {
        source = .fixedValue(value)
    }

    init(_ group: GroupModel?) {
        source = .group(group)
    }

    init(_ viewModel: any GroupEditFormViewModel) {
        source = .viewModel(viewModel)
    }

    var body: some View {
        switch value {
        case .remoteImage(let attachment):
            AttachmentRequestView(attachment: attachment, sizingMode: .square)
                .clipShape(.circle)
        case .localImage(let attachment):
            LocalAttachmentView(attachment: attachment)
                .clipShape(.circle)
        case .emoji(let emoji):
            ZStack {
                backgroundView
                Text(emoji)
                    .scaleTextToFit(fraction: 0.8)
            }
        case .initials(let initial):
            ZStack {
                backgroundView
                Text(initial)
                    .scaleTextToFit(fraction: 0.84)
                    .foregroundStyle(.secondary)
            }
        case .add:
            ZStack {
                backgroundView
                Image(systemName: "plus")
                    .scaleImageToFit(fraction: 0.44)
                    .fontWeight(.light)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder var backgroundView: some View {
        Circle()
            .fill(.secondary)
            .opacity(0.1)
    }
}

#Preview {
    VStack {
        GroupImageView(.initials("P"))
            .frame(width: 24, height: 24)

        GroupImageView(.initials("P"))
            .frame(width: 28, height: 28)

        GroupImageView(.initials("F"))
            .frame(width: 44, height: 44)

        GroupImageView(.emoji("😵‍💫"))
            .frame(width: 44, height: 44)
    }
    .nanoAppearance()
}

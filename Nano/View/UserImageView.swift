//
//  UserImageView.swift
//  Nano
//
//  Created by Richard Henry on 1/3/24.
//

import NanoKit
import SwiftUI

struct UserImageView: View {
    enum Source {
        case model(UserModel?)
        case viewModel(UserEditViewModel)
        case fixedValue(Value)
    }

    enum Value: Equatable {
        case remoteImage(assetKey: String)
        case localImage(LocalAttachment)
        case initials(String)
    }

    var source: Source
    var size: PublicImageRequest.Size

    var value: Value {
        switch source {
        case .model(let user):
            if let image = user?.image {
                return .remoteImage(assetKey: image)
            } else if let initial = user?.name.trimmingCharacters(in: .whitespacesAndNewlines).first
            {
                return .initials(String(initial).uppercased())
            } else {
                return .initials("")
            }
        case .viewModel(let model):
            if let image = model.image {
                return .localImage(image)
            } else if let initial = model.name.trimmingCharacters(in: .whitespacesAndNewlines).first
            {
                return .initials(String(initial).uppercased())
            } else {
                return .initials("")
            }
        case .fixedValue(let value):
            return value
        }
    }

    init(_ value: Value, size: PublicImageRequest.Size) {
        source = .fixedValue(value)
        self.size = size
    }

    init(_ user: UserModel?, size: PublicImageRequest.Size) {
        source = .model(user)
        self.size = size
    }

    init(_ viewModel: UserEditViewModel, size: PublicImageRequest.Size) {
        source = .viewModel(viewModel)
        self.size = size
    }

    var body: some View {
        switch value {
        case .remoteImage(let assetKey):
            PublicImageRequestView(assetKey: assetKey, size: size)
                .clipShape(.circle)
        case .localImage(let attachment):
            LocalAttachmentView(attachment: attachment)
                .clipShape(.circle)
        case .initials(let initial):
            ZStack {
                Circle()
                    .fill(.secondary)
                    .opacity(0.1)

                Text(initial)
                    .scaleTextToFit(fraction: 0.84)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

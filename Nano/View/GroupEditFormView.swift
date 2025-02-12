//
//  GroupEditFormView.swift
//  Nano
//
//  Created by Richard Henry on 5/28/24.
//

import NanoCore
import NanoKit
import PhotosUI
import SwiftUI

protocol GroupEditFormViewModel: FormViewModel {
    var name: String { get set }
    var image: LocalAttachment? { get set }
    var emoji: String? { get set }
    var photo: PhotosPickerItem? { get set }
}

struct GroupEditFormView<Model: GroupEditFormViewModel>: View {
    @Bindable var form: Model
    var titleText: LocalizedStringKey
    var submitText: LocalizedStringKey
    @State private var isPhotoPickerVisible = false
    @State private var isEmojiPickerVisible = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    #if os(macOS)
                    imageEditView
                        .listRowSeparator(.hidden)
                    #endif

                    TextField(
                        platformValue(iOS: "Group Name", macOS: "Group Name:"),
                        text: $form.name
                    )
                } header: {
                    #if os(iOS)
                    imageEditView
                    #endif
                }
                .headerProminence(.increased)
            }
            .navigationTitle(titleText)
            .toolbarTitleDisplayMode(.inline)
            .formStyle(.grouped)
            .form(
                form,
                onCompletion: {
                    dismiss()
                }
            )
            .formToolbar(
                for: form,
                submitText: submitText,
                onCancel: {
                    dismiss()
                }
            )
            .photosPicker(
                isPresented: $isPhotoPickerVisible,
                selection: $form.photo,
                matching: .images,
                preferredItemEncoding: .current,
                photoLibrary: .shared()
            )
            .sheet(isPresented: $isEmojiPickerVisible) {
                GroupEmojiPickerView(form: form)
            }
        }
        #if os(macOS)
        .frame(width: 300, height: 330)
        #endif
    }

    @ViewBuilder var imageEditView: some View {
        let groupImageSize: CGFloat = platformValue(iOS: 170, macOS: 140)

        Menu {
            Button("Choose Emoji…", systemImage: "face.smiling") {
                isEmojiPickerVisible = true
            }

            Button("Choose Image…", systemImage: "photo.on.rectangle.angled") {
                isPhotoPickerVisible = true
            }

            if form.image != nil || form.emoji != nil {
                Button("Remove", systemImage: "xmark", role: .destructive) {
                    form.image = nil
                    form.emoji = nil
                }
            }
        } label: {
            VStack(alignment: .center) {
                GroupImageView(form)
                    #if os(iOS)
                .padding(.horizontal)
                    #endif
                    .frame(maxWidth: groupImageSize)

                Group {
                    if form.image == nil, form.emoji == nil {
                        Text("Add Image or Emoji")
                    } else if form.emoji != nil {
                        Text("Edit Emoji")
                    } else {
                        Text("Edit image")
                    }
                }
                .padding(.top, 2)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical)
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        #if os(macOS)
        .padding(.horizontal)
        #else
        .padding(.bottom)
        #endif
        .buttonStyle(.plain)
    }
}

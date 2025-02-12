//
//  UserEditView.swift
//  Nano
//
//  Created by Richard Henry on 5/29/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct UserEditView: View {
    @ViewModel private var form: UserEditViewModel
    @State private var isPhotoPickerVisible = false
    @Environment(\.dismiss) private var dismiss

    init(user: UserModel) {
        _form = UserEditViewModel(user: user).wrapped()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    #if os(macOS)
                    imageEditView
                        .listRowSeparator(.hidden)
                    #endif

                    TextField(
                        platformValue(iOS: "Name", macOS: "Name:"),
                        text: $form.name
                    )
                } header: {
                    #if os(iOS)
                    imageEditView
                    #endif
                }
                .headerProminence(.increased)
            }
            .navigationTitle("Edit Profile")
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
                submitText: "Save",
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
        }
        #if os(macOS)
        .frame(width: 300, height: 330)
        #endif
    }

    @ViewBuilder var imageEditView: some View {
        let userImageSize: CGFloat = platformValue(iOS: 170, macOS: 140)

        Menu {
            Button("Choose Image…", systemImage: "photo.on.rectangle.angled") {
                isPhotoPickerVisible = true
            }

            if form.image != nil {
                Button("Remove", systemImage: "xmark", role: .destructive) {
                    form.image = nil
                }
            }
        } label: {
            VStack(alignment: .center) {
                UserImageView(form, size: .medium)
                    #if os(iOS)
                .padding(.horizontal)
                    #endif
                    .frame(maxWidth: userImageSize)

                Group {
                    if form.image == nil {
                        Text("Add Image")
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

//
//  AttachmentPickerModifier.swift
//  Nano
//
//  Created by Richard Henry on 4/17/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct AttachmentPickerModifier: ViewModifier {
    @Bindable var attachmentPicker: AttachmentPicker
    @Binding var isCameraVisible: Bool
    @Binding var isPhotoPickerVisible: Bool
    @Binding var isFilePickerVisible: Bool

    func body(content: Content) -> some View {
        content
            #if os(iOS)
        .fullScreenCover(isPresented: $isCameraVisible) {
            CameraView(cameraImage: $attachmentPicker.cameraImage)
            .ignoresSafeArea()
        }
            #endif
            .photosPicker(
                isPresented: $isPhotoPickerVisible,
                selection: $attachmentPicker.photos,
                selectionBehavior: .continuousAndOrdered,
                preferredItemEncoding: .current,
                photoLibrary: .shared()
            )
            .fileImporter(
                isPresented: $isFilePickerVisible,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    attachmentPicker.fileURLs += urls
                case .failure(let error):
                    log(error)
                }
            }
    }
}

extension View {
    func attachmentPicker(
        _ attachmentPicker: AttachmentPicker,
        isCameraVisible: Binding<Bool>,
        isPhotoPickerVisible: Binding<Bool>,
        isFilePickerVisible: Binding<Bool>
    ) -> some View {
        let modifier = AttachmentPickerModifier(
            attachmentPicker: attachmentPicker,
            isCameraVisible: isCameraVisible,
            isPhotoPickerVisible: isPhotoPickerVisible,
            isFilePickerVisible: isFilePickerVisible
        )

        return self.modifier(modifier)
    }

    func attachmentPicker(compose: ComposeViewModel) -> some View {
        @Bindable var compose = compose

        return attachmentPicker(
            compose.attachmentPicker,
            isCameraVisible: $compose.isCameraVisible,
            isPhotoPickerVisible: $compose.isPhotoPickerVisible,
            isFilePickerVisible: $compose.isFilePickerVisible
        )
    }
}

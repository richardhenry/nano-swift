//
//  AttachmentPicker.swift
//  NanoKit
//
//  Created by Richard Henry on 2/8/24.
//

import Combine
import NanoCore
import PhotosUI
import SwiftUI

@Observable public final class AttachmentPicker {
    public var attachments = [LocalAttachment]()

    @inlinable
    public var isEmpty: Bool {
        attachments.isEmpty
    }

    public var photos = [PhotosPickerItem]() {
        didSet {
            let old = Set(oldValue.compactMap { $0.itemIdentifier })
            let new = Set(photos.compactMap { $0.itemIdentifier })
            attachments =
                attachments.filter {
                    if let item = $0.source.photosPickerItem {
                        if let id = item.itemIdentifier {
                            return new.contains(id)
                        } else {
                            assertionFailure()
                            return false
                        }
                    } else {
                        return true
                    }
                }
                + photos.filter {
                    if let id = $0.itemIdentifier {
                        return new.subtracting(old).contains(id)
                    } else {
                        return false
                    }
                }
                .map {
                    LocalAttachment($0)
                }
        }
    }

    public var fileURLs = [URL]() {
        didSet {
            let old = Set(oldValue)
            let new = Set(fileURLs)
            attachments =
                attachments.filter {
                    if let url = $0.source.fileURL {
                        return new.contains(url)
                    } else {
                        return true
                    }
                }
                + fileURLs.filter {
                    new.subtracting(old).contains($0)
                }
                .map {
                    LocalAttachment($0)
                }
        }
    }

    #if os(iOS)
    public var cameraImage: PlatformImage? {
        didSet {
            if let newValue = cameraImage {
                asyncHandleImage(newValue)
            }
        }
    }
    #endif

    public init() {}

    public func reset() {
        photos.removeAll()
        fileURLs.removeAll()
        #if os(iOS)
        cameraImage = nil
        #endif
    }

    public func remove(_ attachment: LocalAttachment) {
        switch attachment.source {
        case .photosPicker(let item):
            photos.removeAll {
                $0.itemIdentifier == item.itemIdentifier
            }
        case .localFile(let url):
            fileURLs.removeAll {
                $0 == url
            }
        case .encryptedAttachment:
            attachments.removeAll {
                $0 == attachment
            }
        case .publicImage:
            fatalError("AttachmentPicker cannot contain remote public images.")
        }
    }

    public func asyncHandleImage(_ newValue: PlatformImage) {
        Task.detached(priority: .userInitiated) { [self] in
            do {
                var targetURL = try FileManager.default.randomSecureTemporaryFile(
                    contentType: .heif
                )
                try newValue.writeHEIFDataOriented(to: targetURL, compressionQuality: 1)
                try FileManager.default.makeSecure(&targetURL)

                await MainActor.run { [targetURL] in
                    fileURLs.append(targetURL)
                }
            } catch {
                log(error)
            }
        }
    }
}

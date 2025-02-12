//
//  SendFeedbackUseCase.swift
//  NanoKit
//
//  Created by Richard Henry on 4/19/24.
//

import Foundation
import NanoCore

public struct SendFeedbackUseCase: UseCase {
    public var fileManager = FileManager.default
    public var feedbackId = UUID()
    public var userId: UserID?
    public var text: String
    public var attachmentPicker: AttachmentPicker
    public var dateTime = Date()

    public init(userId: UserID?, text: String, attachmentPicker: AttachmentPicker) {
        self.userId = userId
        self.text = text
        self.attachmentPicker = attachmentPicker
    }

    public func run() async throws {
        let directoryURL = try fileManager.secureAppGroupDirectory(path: "Feedback-\(feedbackId)")

        defer {
            do {
                try fileManager.removeItem(at: directoryURL)
            } catch {
                log(error)
            }
        }

        for attachment in attachmentPicker.attachments {
            if case .localFile(let file) = attachment.content {
                try fileManager.copyItem(
                    at: file.url,
                    to: directoryURL.appending(path: file.url.basename)
                )
            } else {
                throw error("Attachment(s) are not ready.")
            }
        }

        try fileManager.copyItem(
            at: Logger.shared.directoryURL,
            to: directoryURL.appending(
                path: Logger.shared.directoryName,
                directoryHint: .isDirectory
            )
        )

        var textURL = directoryURL.appending(path: "feedback.txt")
        fileManager.createFile(atPath: textURL.path, contents: nil)
        try fileManager.makeSecure(&textURL)
        try textContent().write(to: textURL, atomically: true, encoding: .utf8)

        var coordinatorError: NSError?
        var moveError: Error?
        var archiveURL: URL?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(
            readingItemAt: directoryURL,
            options: .forUploading,
            error: &coordinatorError
        ) { resultURL in
            do {
                let temporaryURL = try fileManager.randomSecureTemporaryFile()
                try fileManager.moveItem(at: resultURL, to: temporaryURL)
                archiveURL = temporaryURL
            } catch {
                moveError = error
            }
        }

        if let error = moveError ?? coordinatorError {
            throw error
        }

        guard let compressedURL = archiveURL else {
            throw error("Archive failed.")
        }

        defer {
            do {
                try fileManager.removeItem(at: compressedURL)
            } catch {
                log(error)
            }
        }

        try await FileUpload(fileType: .debug, localURL: compressedURL).send()
    }

    func textContent() -> String {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        dateFormat.timeZone = TimeZone(identifier: "UTC")
        dateFormat.locale = Locale(identifier: "en_US_POSIX")

        return """
            Feedback ID: \(feedbackId)
            User ID: \(userId?.description ?? "(nil)")
            User Agent: \(Request.userAgent)
            Date/Time (UTC): \(dateFormat.string(from: dateTime))
            ---
            \(text)
            """
    }
}

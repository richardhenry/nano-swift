//
//  FileUpload.swift
//  NanoKit
//
//  Created by Richard Henry on 2/8/24.
//

import Foundation
import NanoCore

public final class FileUpload: Sendable {
    static let minPresignedLifetime: Timestamp = .minutes(10)

    public let fileType: RemoteFileType
    public let localURL: URL

    public var key: String {
        return localURL.basename
    }

    public init(fileType: RemoteFileType, localURL: URL) throws {
        guard localURL.basename.count == 44 else {
            throw error("Not a valid filename: \(localURL.basename)")
        }

        self.fileType = fileType
        self.localURL = localURL
    }

    private let state = FileUploadState()

    public func send() async throws {
        let session = try await DataStore.shared.read { db in
            try SessionModel.fetchExpect(db)
        }

        let presignedUpload: PresignedUploadPayload

        if let existing = await state.getPresignedUpload() {
            presignedUpload = existing
        } else {
            let request = try APIRequest(
                path: "file/\(fileType)/\(key)",
                method: .put,
                session: session
            )

            do {
                if let value = try await request.send(decoding: PresignedUploadPayload.self).value {
                    presignedUpload = value
                } else {
                    throw error("No presigned upload URL was provided by the server.")
                }
            } catch {
                if let error = error as? ServerError, error == .alreadyExists {
                    return
                } else {
                    throw error
                }
            }

            await state.setPresignedUpload(presignedUpload)
        }

        var request = URLRequest(url: presignedUpload.url)
        request.httpMethod = "PUT"
        request.setValue(fileType.contentType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.upload(
            for: request,
            fromFile: localURL
        )

        guard let response = response as? HTTPURLResponse else {
            throw error("The server did not respond: \(response)")
        }

        guard response.statusCode == 200 else {
            throw error("The server responded with a non-200 status code: \(response)")
        }
    }
}

actor FileUploadState {
    private var presignedUpload: PresignedUploadPayload?

    func getPresignedUpload() -> PresignedUploadPayload? {
        if let existing = presignedUpload,
            Timestamp() < existing.expiresAt - FileUpload.minPresignedLifetime
        {
            return existing
        } else {
            return nil
        }
    }

    func setPresignedUpload(_ value: PresignedUploadPayload?) {
        presignedUpload = value
    }
}

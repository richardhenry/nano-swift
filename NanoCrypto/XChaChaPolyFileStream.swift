//
//  XChaChaPolyFileStream.swift
//  NanoCrypto
//
//  Created by Richard Henry on 2/9/24.
//

import Clibsodium
import CryptoKit
import Foundation
import NanoCore

/// Streaming implementation of XChaCha20-Poly1305 for file encryption.
///
/// This API encrypts or decrypts a file without loading the entirety of a large file into memory.
///
public struct XChaChaPolyFileStream {
    public let chunkSize: Int

    /// Initialize a new stream cipher.
    ///
    /// - Parameters:
    ///   - chunkSize: The number of bytes to read/write at a time.
    public init(chunkSize: Int = 65_536) {
        self.chunkSize = chunkSize
    }

    /// Encrypt a file asynchronously.
    ///
    /// - Parameters:
    ///   - source: The local source file URL to encrypt.
    ///   - target: The local target file URL that will have ciphertext written into it.
    ///   - key: The symmetric encryption key to use for encryption.
    /// - Throws: A `ChaChaPolyFileStreamError` or a system I/O error.
    public func encrypt(
        source sourceURL: URL,
        target targetURL: URL,
        key: SymmetricKey
    )
        async throws
    {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated)
                .async {
                    do {
                        try self.encrypt(source: sourceURL, target: targetURL, key: key)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    /// Encrypt a file.
    ///
    /// - Parameters:
    ///   - source: The local source file URL to encrypt.
    ///   - target: The local target file URL that will have ciphertext written into it.
    ///   - key: The symmetric encryption key to use for encryption.
    /// - Throws: A `ChaChaPolyFileStreamError` or a system I/O error.
    public func encrypt(source sourceURL: URL, target targetURL: URL, key: SymmetricKey) throws {
        guard key.bitCount == XChaChaPoly.keyBytes * 8 else {
            throw error("Key size is incorrect.")
        }

        guard let sourcePtr = fopen(sourceURL.path, "rb") else {
            throw error("Unable to open source file.")
        }
        defer { fclose(sourcePtr) }

        var targetURL = targetURL
        FileManager.default.createFile(atPath: targetURL.path, contents: nil)
        try FileManager.default.makeSecure(&targetURL)

        guard let targetPtr = fopen(targetURL.path, "wb") else {
            throw error("Unable to open target file.")
        }
        defer { fclose(targetPtr) }

        var state = crypto_secretstream_xchacha20poly1305_state()

        defer {
            let bytesToClear = MemoryLayout.size(ofValue: state)
            withUnsafeMutablePointer(to: &state) { ptr in
                sodium_memzero(ptr, bytesToClear)
            }
        }

        var inBuffer = [UInt8](repeating: 0, count: chunkSize)
        var outBuffer = [UInt8](repeating: 0, count: chunkSize + tagBytes)
        var header = [UInt8](repeating: 0, count: headerBytes)
        var outSize: UInt64 = 0

        let initResult = key.withUnsafeBytes { keyPtr in
            crypto_secretstream_xchacha20poly1305_init_push(
                &state,
                &header,
                keyPtr.bindMemory(to: UInt8.self).baseAddress!
            )
        }

        guard initResult == 0 else {
            throw error("Encryption init failed with error: \(initResult)")
        }

        guard fwrite(header, 1, header.count, targetPtr) == header.count else {
            throw error("Unable to write header to file.")
        }

        var isEOF = false
        while !isEOF {
            let readSize = UInt64(fread(&inBuffer, 1, inBuffer.count, sourcePtr))
            isEOF = feof(sourcePtr) != 0

            let tag: UInt8 = isEOF ? finalTag : 0

            let result = crypto_secretstream_xchacha20poly1305_push(
                &state,
                &outBuffer,
                &outSize,
                &inBuffer,
                readSize,
                nil,
                0,
                tag
            )

            guard result == 0 else {
                throw error("Encryption of chunk failed with error: \(result)")
            }

            guard fwrite(&outBuffer, 1, Int(outSize), targetPtr) == outSize else {
                throw error("Unable to write chunk to file.")
            }
        }
    }

    /// Decrypt a file asynchronously.
    ///
    /// - Parameters:
    ///   - source: The local source file URL that contains ciphertext.
    ///   - target: The local target file URL that will have decrypted content written into it.
    ///   - key: The symmetric encryption key to use for decryption.
    /// - Throws: A `ChaChaPolyFileStreamError` or a system I/O error.
    public func decrypt(
        source sourceURL: URL,
        target targetURL: URL,
        key: SymmetricKey
    )
        async throws
    {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated)
                .async {
                    do {
                        try self.decrypt(source: sourceURL, target: targetURL, key: key)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    /// Decrypt a file.
    ///
    /// - Parameters:
    ///   - source: The local source file URL that contains ciphertext.
    ///   - target: The local target file URL that will have decrypted content written into it.
    ///   - key: The symmetric encryption key to use for decryption.
    /// - Throws: A `ChaChaPolyFileStreamError` or a system I/O error.
    public func decrypt(source sourceURL: URL, target targetURL: URL, key: SymmetricKey) throws {
        guard let sourcePtr = fopen(sourceURL.path, "rb") else {
            throw error("Unable to open source file.")
        }
        defer { fclose(sourcePtr) }

        var outputFile = targetURL
        FileManager.default.createFile(atPath: outputFile.path, contents: nil)
        try FileManager.default.makeSecure(&outputFile)

        guard let targetPtr = fopen(outputFile.path, "wb") else {
            throw error("Unable to open target file.")
        }
        defer { fclose(targetPtr) }

        var state = crypto_secretstream_xchacha20poly1305_state()

        defer {
            let bytesToClear = MemoryLayout.size(ofValue: state)
            withUnsafeMutablePointer(to: &state) { ptr in
                sodium_memzero(ptr, bytesToClear)
            }
        }

        var inBuffer = [UInt8](repeating: 0, count: chunkSize + tagBytes)
        var outBuffer = [UInt8](repeating: 0, count: chunkSize)
        var header = [UInt8](repeating: 0, count: headerBytes)
        var outSize: UInt64 = 0
        var tag: UInt8 = 0

        guard fread(&header, 1, headerBytes, sourcePtr) == headerBytes else {
            throw error("Unable to read header.")
        }

        let initResult = key.withUnsafeBytes { keyPtr in
            crypto_secretstream_xchacha20poly1305_init_pull(
                &state,
                header,
                keyPtr.bindMemory(to: UInt8.self).baseAddress!
            )
        }

        guard initResult == 0 else {
            throw error("Decryption init failed with error: \(initResult)")
        }

        var isEOF = false
        while !isEOF {
            let readSize = UInt64(fread(&inBuffer, 1, inBuffer.count, sourcePtr))
            isEOF = feof(sourcePtr) != 0

            let result = crypto_secretstream_xchacha20poly1305_pull(
                &state,
                &outBuffer,
                &outSize,
                &tag,
                inBuffer,
                readSize,
                nil,
                0
            )

            guard result == 0 else {
                throw error("Decryption of chunk failed with error: \(result)")
            }

            if tag == finalTag, !isEOF {
                throw error("Encountered final tag before end of file.")
            } else if tag != finalTag, isEOF {
                throw error("Encountered end of file before final tag. File is truncated.")
            }

            guard fwrite(&outBuffer, 1, Int(outSize), targetPtr) == outSize else {
                throw error("Unable to write chunk to file.")
            }
        }
    }

    private let tagBytes = Int(crypto_secretstream_xchacha20poly1305_ABYTES)
    private let headerBytes = Int(crypto_secretstream_xchacha20poly1305_HEADERBYTES)
    private let finalTag = UInt8(crypto_secretstream_xchacha20poly1305_TAG_FINAL)
}

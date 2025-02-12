//
//  PadmeFileStream.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/16/24.
//

import Foundation
import NanoCore

/// Streaming implementation of the Padmé padding scheme for file padding.
///
/// This API adds or removes padding to a file without loading the entirety of a large file into memory.
///
public struct PadmeFileStream {
    public let chunkSize: Int

    /// Initialize a new stream padder.
    ///
    /// - Parameters:
    ///   - chunkSize: The number of bytes to read/write a time.
    public init(chunkSize: Int = 65_536) {
        self.chunkSize = chunkSize
    }

    /// Add padding to a file asynchronously.
    ///
    /// - Parameters:
    ///   - source: The local source file URL to pad.
    ///   - target: The local target file URL that will have padded data written into it.
    ///   - sourceSize: The size of the source file in bytes. If nil, this value will be read out of the file attributes.
    /// - Throws: A `PadmeFileStreamError` or or a system I/O error.
    public func pad(
        source sourceURL: URL,
        target targetURL: URL,
        sourceSize: UInt64? = nil
    )
        async throws
    {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated)
                .async {
                    do {
                        try self.pad(source: sourceURL, target: targetURL, sourceSize: sourceSize)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    /// Add padding to a file.
    ///
    /// - Parameters:
    ///   - source: The local source file URL to pad.
    ///   - target: The local target file URL that will have padded data written into it.
    ///   - sourceSize: The size of the source file in bytes. If nil, this value will be read out of the file attributes.
    /// - Throws: A `PadmeFileStreamError` or or a system I/O error.
    public func pad(source sourceURL: URL, target targetURL: URL, sourceSize: UInt64? = nil) throws
    {
        guard
            let sourceSize = try sourceSize
                ?? FileManager.default
                .attributesOfItem(
                    atPath: sourceURL.path
                )[.size] as? UInt64
        else {
            throw error("Unable to read source file attributes.")
        }

        let targetSize = Padme.size(for: sourceSize)

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

        var buffer = [UInt8](repeating: 0, count: chunkSize)
        var writeSize: UInt64 = 0

        let header = [UInt8](Padme.header(originalSize: sourceSize))
        guard fwrite(header, 1, header.count, targetPtr) == header.count else {
            throw error("Unable to write header to target file.")
        }

        var (isEOF, isPad) = (false, false)
        while writeSize < targetSize {
            let bufferSize: Int
            if !isEOF {
                bufferSize = fread(&buffer, 1, buffer.count, sourcePtr)
                isEOF = feof(sourcePtr) != 0
                let outSize = writeSize + UInt64(bufferSize)
                if isEOF, outSize != sourceSize {
                    throw error(
                        "File size mismatch detected during write. Expected: \(sourceSize) Wrote: \(outSize)"
                    )
                }
            } else {
                bufferSize = Int(min(targetSize - writeSize, UInt64(chunkSize)))
                if !isPad {
                    buffer = [UInt8](repeating: 0, count: chunkSize)
                    isPad = true
                }
            }

            guard fwrite(buffer, 1, bufferSize, targetPtr) == bufferSize else {
                throw error("Write of padded data failed.")
            }

            writeSize += UInt64(bufferSize)
        }

        guard writeSize == targetSize else {
            throw error("File size mismatch. Expected: \(targetSize) Wrote: \(writeSize)")
        }
    }

    /// Remove padding from a file asynchronously.
    ///
    /// - Parameters:
    ///   - source: The local source file URL that contains padding and a padding header.
    ///   - target: The local target file URL that will have unpadded data written into it.
    /// - Throws: A `PadmeFileStreamError` or or a system I/O error.
    public func unpad(source sourceURL: URL, target targetURL: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated)
                .async {
                    do {
                        try self.unpad(source: sourceURL, target: targetURL)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    /// Remove padding from a file.
    ///
    /// - Parameters:
    ///   - source: The local source file URL that contains padding and a padding header.
    ///   - target: The local target file URL that will have unpadded data written into it.
    /// - Throws: A `PadmeFileStreamError` or or a system I/O error.
    public func unpad(source sourceURL: URL, target targetURL: URL) throws {
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

        var buffer = [UInt8](repeating: 0, count: chunkSize)
        var header = [UInt8](repeating: 0, count: MemoryLayout<UInt64>.size)
        var writeSize: UInt64 = 0

        guard fread(&header, 1, header.count, sourcePtr) == header.count else {
            throw error("Unable to read header.")
        }

        let sourceSize = try Padme.loadSize(fromHeader: Data(header)) as UInt64

        var isEOF = false
        while writeSize < sourceSize, !isEOF {
            let bufferSize = fread(
                &buffer,
                1,
                Int(min(UInt64(buffer.count), sourceSize - writeSize)),
                sourcePtr
            )
            isEOF = feof(sourcePtr) != 0

            guard fwrite(buffer, 1, bufferSize, targetPtr) == bufferSize else {
                throw error("Write of unpadded data failed.")
            }

            writeSize += UInt64(bufferSize)
        }

        guard writeSize == sourceSize else {
            throw error("File size mismatch. Expected: \(sourceSize) Wrote: \(writeSize)")
        }
    }
}

//
//  Padme.swift
//  NanoCrypto
//
//  Created by Richard Henry on 3/15/24.
//

import Foundation
import NanoCore

let maxBytes: Int = 104_857_600  // 100Mb

/// Implements the Padmé padding scheme and a header mechanism for storing the unpadded size.
///
/// The Padmé algorithm (for calculating the padding size) is described here:
/// https://nikirill.com/files/purbs.pdf
///
public enum Padme {
    /// Returns the total padded size for a given original size using the Padmé padding scheme.
    ///
    /// The return value will always be at least 10 bytes.
    ///
    public static func size(for originalSize: UInt64) -> UInt64 {
        guard originalSize > 0 else { return 0 }
        let e = 63 - originalSize.leadingZeroBitCount
        let s = 64 - e.leadingZeroBitCount
        let z = e - s
        let mask = UInt64((1 << z) - 1)
        let size = (originalSize + mask) & ~mask
        return max(size, 10)
    }

    /// Returns padded data from the original data using the Padmé padding scheme.
    ///
    /// The original unpadded size will be prefixed to the data as a 4 byte header, and the padding will be appended to the end.
    ///
    public static func pad(originalData: Data) throws -> Data {
        guard originalData.count <= maxBytes else {
            // If you hit this, you should be using PadmeFileStream instead.
            throw error("Data is too large to pad in memory: \(originalData.count)")
        }

        let originalSize = originalData.count
        let paddedSize = Int(size(for: UInt64(originalSize)))

        let paddingSize = paddedSize - originalSize
        var paddedData = originalData
        paddedData.append(contentsOf: [UInt8](repeating: 0, count: paddingSize))

        return header(originalSize: UInt32(originalSize)) + paddedData
    }

    /// Returns unpadded data by removing the appended padding and prepended header.
    public static func unpad(paddedData: Data) throws -> Data {
        guard paddedData.count <= maxBytes * Int(1.2) else {
            throw error("Data is too large to unpad in memory: \(paddedData.count)")
        }

        let headerSize = MemoryLayout<UInt32>.size
        guard paddedData.count >= headerSize else {
            throw error("Padded data is too small to contain a header.")
        }

        let originalSize = Int(try loadSize(fromHeader: paddedData.prefix(headerSize)) as UInt32)
        guard originalSize > 0 && paddedData.count >= originalSize + headerSize else {
            throw error(
                "Some padded data is missing. Expected: \(originalSize) Actual: \(paddedData.count)"
            )
        }

        return paddedData.subdata(in: headerSize..<originalSize + headerSize)
    }

    /// Returns a padding header for the provided original size.
    ///
    /// The number of header bytes will be determined by the unsigned integer type (i.e. 4 bytes for a UInt32, 8 bytes for UInt64).
    ///
    public static func header<T: FixedWidthInteger & UnsignedInteger>(originalSize: T) -> Data {
        var bytes = originalSize.bigEndian
        return Data(bytes: &bytes, count: MemoryLayout<T>.size)
    }

    /// Returns the original size from a given header.
    ///
    /// The size of the header must be equal to `MemoryLayout<T>.size` where `T` is the unsigned integer type.
    ///
    public static func loadSize<T: FixedWidthInteger & UnsignedInteger>(
        fromHeader header: Data
    )
        throws -> T
    {
        guard header.count == MemoryLayout<T>.size else {
            throw error("Header size is incorrect.")
        }

        return header.withUnsafeBytes {
            $0.load(as: T.self).bigEndian
        }
    }
}

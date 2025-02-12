//
//  PlatformImage+Encoding.swift
//  NanoKit
//
//  Created by Richard Henry on 2/12/24.
//

import CoreImage
import Foundation
import NanoCore

extension PlatformImage {
    /**
     Returns the HEIF data representation of this image correcting for the input orientation.

     - Parameters:
        - compressionQuality: The compression quality to use, between 0 and 1.
     */
    public func heifDataOriented(compressionQuality: CGFloat) throws -> Data {
        let (ciImage, colorSpace) = try ciImageOrientedWithColorSpace()

        let context = CIContext()
        let data = context.heifRepresentation(
            of: ciImage,
            format: .RGBA8,
            colorSpace: colorSpace,
            options: [
                kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption:
                    compressionQuality
            ]
        )

        if let data = data {
            return data
        } else {
            throw error("CI rendering to HEIF failed.")
        }
    }

    /// Returns the PNG data representation of this image correcting for the input orientation.
    public func pngDataOriented() throws -> Data {
        let (ciImage, colorSpace) = try ciImageOrientedWithColorSpace()

        let context = CIContext()
        let data = context.pngRepresentation(of: ciImage, format: .RGBA8, colorSpace: colorSpace)

        if let data = data {
            return data
        } else {
            throw error("CI rendering to PNG failed.")
        }
    }

    /**
     Returns the JPEG data representation of this image correcting for the input orientation.

     - Parameters:
        - compressionQuality: The compression quality to use, between 0 and 1.
     */
    public func jpegDataOriented(compressionQuality: CGFloat) throws -> Data {
        let (ciImage, colorSpace) = try ciImageOrientedWithColorSpace()

        let context = CIContext()
        let data = context.jpegRepresentation(
            of: ciImage,
            colorSpace: colorSpace,
            options: [
                kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption:
                    compressionQuality
            ]
        )

        if let data = data {
            return data
        } else {
            throw error("CI rendering to JPEG failed.")
        }
    }

    /**
     Writes the HEIF representation of this image to a file correcting for the input orientation.

     - Parameters:
        - url: The file URL to write the data to.
        - compressionQuality: The compression quality to use, between 0 and 1.
     */
    public func writeHEIFDataOriented(to url: URL, compressionQuality: CGFloat) throws {
        let (ciImage, colorSpace) = try ciImageOrientedWithColorSpace()

        try CIContext()
            .writeHEIFRepresentation(
                of: ciImage,
                to: url,
                format: .RGBA8,
                colorSpace: colorSpace,
                options: [
                    kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption:
                        compressionQuality
                ]
            )
    }

    /**
     Writes the PNG representation of this image to a file correcting for the input orientation.

     - Parameters:
        - url: The file URL to write the data to.
     */
    public func writePNGDataOriented(to url: URL) throws {
        let (ciImage, colorSpace) = try ciImageOrientedWithColorSpace()

        try CIContext()
            .writePNGRepresentation(
                of: ciImage,
                to: url,
                format: .RGBA8,
                colorSpace: colorSpace
            )
    }

    /**
     Writes the JPEG representation of this image to a file correcting for the input orientation.

     - Parameters:
        - url: The file URL to write the data to.
        - compressionQuality: The compression quality to use, between 0 and 1.
     */
    public func writeJPEGDataOriented(to url: URL, compressionQuality: CGFloat) throws {
        let (ciImage, colorSpace) = try ciImageOrientedWithColorSpace()

        try CIContext()
            .writeJPEGRepresentation(
                of: ciImage,
                to: url,
                colorSpace: colorSpace,
                options: [
                    kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption:
                        compressionQuality
                ]
            )
    }

    // MARK: - Implementation

    /// Converts the `UIImage.Orientation` of this image to a `CGImagePropertyOrientation` value.
    private var cgImageOrientation: CGImagePropertyOrientation {
        get throws {
            #if os(macOS)
            return .up
            #else
            switch imageOrientation {
            case .up:
                return .up
            case .upMirrored:
                return .upMirrored
            case .down:
                return .down
            case .downMirrored:
                return .downMirrored
            case .left:
                return .left
            case .leftMirrored:
                return .leftMirrored
            case .right:
                return .right
            case .rightMirrored:
                return .rightMirrored
            @unknown default:
                throw error("Unhandled image orientation: \(imageOrientation)")
            }
            #endif
        }
    }

    /// Returns a CIImage transformed with the correct orientation and color space.
    private func ciImageOrientedWithColorSpace() throws -> (CIImage, CGColorSpace) {
        var ciImage: CIImage

        #if os(macOS)
        var rect = NSRect(origin: .zero, size: size)
        if let cgImage = self.cgImage(forProposedRect: &rect, context: .current, hints: nil) {
            ciImage = CIImage(cgImage: cgImage)
        } else {
            throw error("Failed to initialize CIImage.")
        }
        #else
        if let value = self.ciImage {
            ciImage = value
        } else if let value = cgImage {
            ciImage = CIImage(cgImage: value)
        } else {
            throw error("Failed to initialize CIImage.")
        }
        #endif

        var newColorSpace: CGColorSpace

        if let oldColorSpace = ciImage.colorSpace {
            if oldColorSpace.model == .rgb {
                newColorSpace = oldColorSpace
            } else {
                if let sRGB = CGColorSpace(name: CGColorSpace.sRGB),
                    let value = ciImage.matchedFromWorkingSpace(to: sRGB)
                {
                    ciImage = value
                    newColorSpace = sRGB
                } else {
                    throw error(
                        "Failed to convert CIImage to sRGB from color space: \(oldColorSpace)"
                    )
                }
            }
        } else {
            throw error("CIImage has no color space.")
        }

        return (ciImage.oriented(try cgImageOrientation), newColorSpace)
    }
}

extension CGImagePropertyOrientation {
    public var isRotated90Degrees: Bool {
        switch self {
        case .up, .upMirrored, .down, .downMirrored:
            return false
        case .left, .leftMirrored, .right, .rightMirrored:
            return true
        }
    }
}

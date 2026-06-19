import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Encodes a `CGImage` into PNG/JPEG data using ImageIO.
enum ImageEncoder {
    static func encode(_ image: CGImage, format: ImageFormat, jpegQuality: Double) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            format.utType.identifier as CFString,
            1,
            nil
        ) else {
            throw CaptureError.encodingFailed
        }

        var properties: [CFString: Any] = [:]
        if format == .jpeg {
            properties[kCGImageDestinationLossyCompressionQuality] = max(0.0, min(1.0, jpegQuality))
        }

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw CaptureError.encodingFailed }
        return data as Data
    }
}

import CoreGraphics
import Foundation

/// Stitches per-display captures into a single image laid out to match the
/// physical display arrangement, and supports cropping a global rectangle out
/// of that virtual desktop.
enum ImageCompositor {

    /// One display's rendered image plus where it lives on the virtual desktop.
    struct Tile {
        let bounds: CGRect          // global, top-left origin, points
        let image: CGImage
    }

    /// Composites tiles into a single image. `scale` converts points to pixels
    /// for the output canvas.
    /// - Returns: the composited image and the virtual-desktop origin (points).
    static func composite(tiles: [Tile], scale: CGFloat) throws -> (image: CGImage, origin: CGPoint) {
        guard !tiles.isEmpty else { throw CaptureError.noDisplaysAvailable }

        let virtualBounds = tiles.reduce(CGRect.null) { $0.union($1.bounds) }
        guard !virtualBounds.isNull, virtualBounds.width > 0, virtualBounds.height > 0 else {
            throw CaptureError.compositingFailed
        }

        let pixelWidth = Int((virtualBounds.width * scale).rounded())
        let pixelHeight = Int((virtualBounds.height * scale).rounded())

        guard let context = makeContext(width: pixelWidth, height: pixelHeight) else {
            throw CaptureError.compositingFailed
        }

        for tile in tiles {
            // Position within the virtual desktop, top-left origin, in points.
            let localX = tile.bounds.minX - virtualBounds.minX
            let localTop = tile.bounds.minY - virtualBounds.minY

            // Convert to the context's bottom-left origin, in pixels.
            let destX = localX * scale
            let destY = (virtualBounds.height - localTop - tile.bounds.height) * scale
            let destRect = CGRect(
                x: destX,
                y: destY,
                width: tile.bounds.width * scale,
                height: tile.bounds.height * scale
            )
            context.draw(tile.image, in: destRect)
        }

        guard let image = context.makeImage() else { throw CaptureError.compositingFailed }
        return (image, virtualBounds.origin)
    }

    /// Crops a global rectangle (points, top-left origin) out of a composited
    /// image whose top-left corresponds to `origin`.
    static func crop(_ image: CGImage, globalRect: CGRect, origin: CGPoint, scale: CGFloat) throws -> CGImage {
        let local = CGRect(
            x: (globalRect.minX - origin.x) * scale,
            y: (globalRect.minY - origin.y) * scale,
            width: globalRect.width * scale,
            height: globalRect.height * scale
        ).integral

        let clamped = local.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard !clamped.isNull, clamped.width >= 1, clamped.height >= 1 else {
            throw CaptureError.emptySelection
        }
        guard let cropped = image.cropping(to: clamped) else { throw CaptureError.compositingFailed }
        return cropped
    }

    private static func makeContext(width: Int, height: Int) -> CGContext? {
        guard width > 0, height > 0 else { return nil }
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )
        context?.interpolationQuality = .high
        return context
    }
}

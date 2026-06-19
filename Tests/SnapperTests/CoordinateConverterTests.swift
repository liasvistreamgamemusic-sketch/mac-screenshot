import CoreGraphics
import XCTest
@testable import Snapper

final class ImageCompositorCropTests: XCTestCase {
    /// A 200×200pt virtual desktop at the origin, rendered 2× → 400×400px.
    private func makeTestImage(width: Int, height: Int) -> CGImage {
        let cs = CGColorSpace(name: CGColorSpace.sRGB)!
        let ctx = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )!
        ctx.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()!
    }

    func testCropMapsPointsToPixels() throws {
        let image = makeTestImage(width: 400, height: 400)
        let region = CGRect(x: 50, y: 50, width: 100, height: 100) // points
        let cropped = try ImageCompositor.crop(image, globalRect: region, origin: .zero, scale: 2.0)
        XCTAssertEqual(cropped.width, 200)
        XCTAssertEqual(cropped.height, 200)
    }

    func testEmptyRegionThrows() {
        let image = makeTestImage(width: 400, height: 400)
        XCTAssertThrowsError(
            try ImageCompositor.crop(image, globalRect: CGRect(x: 1000, y: 1000, width: 10, height: 10),
                                     origin: .zero, scale: 2.0)
        )
    }
}

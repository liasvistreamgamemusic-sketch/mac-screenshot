import AppKit
import CoreGraphics

/// Converts between Cocoa's bottom-left global coordinate space (used by
/// `NSScreen`/`NSWindow`) and Core Graphics' top-left global space (used by
/// `CGDisplayBounds` and ScreenCaptureKit).
enum CoordinateConverter {
    /// Height of the primary display (the one whose origin is `.zero`), which is
    /// the axis the two coordinate systems flip around.
    static var primaryDisplayHeight: CGFloat {
        if let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero }) {
            return primary.frame.height
        }
        return NSScreen.main?.frame.height ?? CGDisplayBounds(CGMainDisplayID()).height
    }

    /// Converts a Cocoa (bottom-left origin) global rect to a Core Graphics
    /// (top-left origin) global rect.
    static func cocoaToCG(_ rect: CGRect) -> CGRect {
        let height = primaryDisplayHeight
        return CGRect(
            x: rect.minX,
            y: height - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}

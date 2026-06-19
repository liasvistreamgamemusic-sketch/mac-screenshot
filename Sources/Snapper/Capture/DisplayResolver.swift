import AppKit
import CoreGraphics

/// Pure geometry/identity helpers for locating displays. Kept free of
/// ScreenCaptureKit so it can be reasoned about and unit-tested in isolation.
enum DisplayResolver {

    /// The display that should be treated as "active": the one containing the
    /// frontmost window, falling back to the display under the cursor, then the
    /// main display.
    static func activeDisplayID() -> CGDirectDisplayID? {
        if let id = displayContainingFrontmostWindow() { return id }
        if let id = displayUnderCursor() { return id }
        return CGMainDisplayID()
    }

    /// Bounds of a display in global, top-left-origin coordinates (matches
    /// `CGDisplayBounds` and ScreenCaptureKit's `SCDisplay.frame`).
    static func bounds(of displayID: CGDirectDisplayID) -> CGRect {
        CGDisplayBounds(displayID)
    }

    /// The union of all active displays' bounds — i.e. the whole virtual desktop.
    static func virtualDesktopBounds() -> CGRect {
        activeDisplayIDs().reduce(CGRect.null) { $0.union(CGDisplayBounds($1)) }
    }

    static func activeDisplayIDs() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &ids, &count) == .success else { return [] }
        return Array(ids.prefix(Int(count)))
    }

    // MARK: - Private

    private static func displayContainingFrontmostWindow() -> CGDirectDisplayID? {
        guard let window = WindowResolver.frontmostWindow() else { return nil }
        return displayContaining(rect: window.bounds)
    }

    private static func displayUnderCursor() -> CGDirectDisplayID? {
        // NSEvent.mouseLocation is bottom-left origin; convert to top-left global.
        let location = NSEvent.mouseLocation
        guard let primaryHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? NSScreen.screens.map({ $0.frame.maxY }).max()
        else { return nil }
        let topLeftPoint = CGPoint(x: location.x, y: primaryHeight - location.y)
        return displayContaining(point: topLeftPoint)
    }

    private static func displayContaining(rect: CGRect) -> CGDirectDisplayID? {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        return displayContaining(point: center) ?? displayMostOverlapping(rect: rect)
    }

    private static func displayContaining(point: CGPoint) -> CGDirectDisplayID? {
        activeDisplayIDs().first { CGDisplayBounds($0).contains(point) }
    }

    private static func displayMostOverlapping(rect: CGRect) -> CGDirectDisplayID? {
        activeDisplayIDs()
            .map { (id: $0, area: intersectionArea(CGDisplayBounds($0), rect)) }
            .filter { $0.area > 0 }
            .max { $0.area < $1.area }?
            .id
    }

    private static func intersectionArea(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let i = a.intersection(b)
        return i.isNull ? 0 : i.width * i.height
    }
}

import CoreGraphics

/// Resolves the pixel/point scale factor for a display.
enum ScreenScale {
    /// Native backing scale of a display (pixels per point). Falls back to 2.0
    /// for Retina-class hardware when the mode cannot be queried.
    static func factor(for displayID: CGDirectDisplayID) -> CGFloat {
        guard let mode = CGDisplayCopyDisplayMode(displayID) else { return 2.0 }
        let pointWidth = CGFloat(mode.width)
        let pixelWidth = CGFloat(mode.pixelWidth)
        guard pointWidth > 0 else { return 2.0 }
        let factor = pixelWidth / pointWidth
        return factor > 0 ? factor : 1.0
    }

    /// Native pixel dimensions of a display.
    static func pixelSize(for displayID: CGDirectDisplayID) -> (width: Int, height: Int) {
        guard let mode = CGDisplayCopyDisplayMode(displayID) else {
            let bounds = CGDisplayBounds(displayID)
            return (Int(bounds.width * 2), Int(bounds.height * 2))
        }
        return (mode.pixelWidth, mode.pixelHeight)
    }
}

import AppKit
import CoreGraphics

/// Locates the "active" window — the one the user is interacting with — so it can
/// be captured on its own. Kept free of ScreenCaptureKit (mirrors
/// `DisplayResolver`) so it can be reasoned about in isolation.
enum WindowResolver {

    /// The frontmost window: the topmost on-screen, normal-layer window owned by
    /// the frontmost application.
    struct FrontmostWindow {
        let id: CGWindowID
        /// Bounds in global, top-left-origin coordinates (matches `CGWindowBounds`).
        let bounds: CGRect
    }

    /// Resolves the frontmost window, or `nil` when none qualifies (e.g. only the
    /// desktop is showing).
    static func frontmostWindow() -> FrontmostWindow? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let pid = frontApp.processIdentifier

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
        else { return nil }

        // Windows are returned front-to-back; the first normal-layer window owned
        // by the frontmost app is the one the user is interacting with.
        for window in windowList {
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? pid_t, ownerPID == pid,
                  let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
                  let number = window[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = window[kCGWindowBounds as String] as? [String: Any],
                  let rect = CGRect(dictionaryRepresentation: boundsDict as CFDictionary),
                  rect.width > 1, rect.height > 1
            else { continue }
            return FrontmostWindow(id: number, bounds: rect)
        }
        return nil
    }
}

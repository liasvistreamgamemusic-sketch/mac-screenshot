import CoreGraphics
import Foundation

/// Helpers for inspecting and requesting the Screen Recording TCC permission,
/// which ScreenCaptureKit requires.
enum ScreenRecordingPermission {
    /// `true` when the app already holds Screen Recording permission.
    static var isGranted: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Triggers the system permission prompt (no-op if already granted).
    @discardableResult
    static func request() -> Bool {
        CGRequestScreenCaptureAccess()
    }
}

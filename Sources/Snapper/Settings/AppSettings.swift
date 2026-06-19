import AppKit
import Carbon.HIToolbox

/// The complete, serializable configuration for the app. A single value type
/// keeps persistence trivial (one Codable blob) and makes the settings UI a
/// pure function of this struct.
struct AppSettings: Codable, Equatable, Sendable {
    // MARK: Output behaviour

    /// When `true` (default) every capture is placed on the pasteboard so the
    /// user can paste immediately — this is the headline feature.
    var copyToClipboard: Bool

    /// When `true` (default) the capture is also written to disk.
    var saveToFile: Bool

    /// Encoding used for files on disk.
    var imageFormat: ImageFormat

    /// JPEG quality (0.0–1.0); ignored for PNG.
    var jpegQuality: Double

    /// Directory captures are written to. Stored as a bookmarkable path string;
    /// `nil` means "use the system default" (Desktop).
    var saveDirectoryPath: String?

    // MARK: Feedback

    /// Play the system shutter sound on capture.
    var playSound: Bool

    /// Post a user notification with a preview after each capture.
    var showNotification: Bool

    // MARK: Lifecycle

    /// Register the app as a login item.
    var launchAtLogin: Bool

    // MARK: Shortcuts

    /// Global shortcut for each capture mode.
    var shortcuts: [CaptureMode: KeyCombo]

    // MARK: Defaults

    static let `default` = AppSettings(
        copyToClipboard: true,
        saveToFile: true,
        imageFormat: .png,
        jpegQuality: 0.9,
        saveDirectoryPath: nil,
        playSound: true,
        showNotification: true,
        launchAtLogin: false,
        shortcuts: [
            // Chosen to avoid clashing with the system ⌘⇧3/4/5 screenshots.
            .region: KeyCombo(keyCode: UInt32(kVK_ANSI_R), modifierFlags: [.control, .option, .command]),
            .activeDisplay: KeyCombo(keyCode: UInt32(kVK_ANSI_D), modifierFlags: [.control, .option, .command]),
            .allDisplays: KeyCombo(keyCode: UInt32(kVK_ANSI_A), modifierFlags: [.control, .option, .command])
        ]
    )

    /// Resolves the effective save directory, creating the default when needed.
    var resolvedSaveDirectory: URL {
        if let path = saveDirectoryPath, !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
    }
}

// MARK: - Codable for the shortcuts dictionary

// `[CaptureMode: KeyCombo]` round-trips with the synthesized Codable conformance:
// because `CaptureMode` is not a bare `String`/`Int` key, Codable encodes the
// dictionary as an array of alternating key/value entries. That is perfectly
// stable for our UserDefaults blob, so no custom coding is required.

import Foundation

/// Central place for app-wide identity constants so they are never hard-coded
/// at multiple call sites.
enum AppInfo {
    static let name = "Snapper"
    static let bundleIdentifier = "dev.snapper.Snapper"

    /// Resolved at runtime from the bundle's Info.plist; falls back to a
    /// sensible default when running outside a bundle (e.g. `swift run`).
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0-dev"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }
}

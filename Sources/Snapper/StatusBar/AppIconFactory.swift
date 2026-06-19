import AppKit

/// Provides the status bar (menu bar) icon. Uses an SF Symbol rendered as a
/// template image so it adapts to light/dark menu bars automatically.
enum AppIconFactory {
    static func statusBarImage() -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: AppInfo.name)?
            .withSymbolConfiguration(config)
        image?.isTemplate = true
        return image
    }
}

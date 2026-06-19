import AppKit
import SwiftUI

/// Hosts `SettingsView` in a standard window. Reused across opens so the app
/// only ever has a single settings window.
@MainActor
final class SettingsWindowController {
    private var window: NSWindow?
    private let store: SettingsStore
    private let hotkeys: HotkeyBindingManager

    init(store: SettingsStore, hotkeys: HotkeyBindingManager) {
        self.store = store
        self.hotkeys = hotkeys
    }

    func show() {
        if let window {
            present(window)
            return
        }

        let hosting = NSHostingController(rootView: SettingsView(store: store, hotkeys: hotkeys))
        let window = NSWindow(contentViewController: hosting)
        window.title = "\(AppInfo.name) 設定"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
        present(window)
    }

    private func present(_ window: NSWindow) {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

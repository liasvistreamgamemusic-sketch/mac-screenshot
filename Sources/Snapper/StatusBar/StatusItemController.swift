import AppKit

/// Owns the menu bar status item — the app's "header" — including its icon and
/// the dropdown menu of capture actions, the clipboard toggle and settings.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    /// Callbacks wired up by the app delegate.
    var onCapture: ((CaptureMode) -> Void)?
    var onOpenSettings: (() -> Void)?
    var onToggleClipboard: (() -> Void)?
    var onQuit: (() -> Void)?

    private let statusItem: NSStatusItem
    private let settingsStore: SettingsStore
    private var clipboardToggleItem: NSMenuItem?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureButton()
        statusItem.menu = buildMenu()
    }

    // MARK: - Status button

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.image = AppIconFactory.statusBarImage()
        button.image?.isTemplate = true
        button.toolTip = "\(AppInfo.name) — スクリーンショット"
        button.setAccessibilityLabel(AppInfo.name)
    }

    // MARK: - Menu construction

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        let header = NSMenuItem(title: "\(AppInfo.name) \(AppInfo.version)", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        for mode in CaptureMode.allCases {
            menu.addItem(captureItem(for: mode))
        }

        menu.addItem(.separator())

        let toggle = NSMenuItem(
            title: "撮影後にクリップボードへコピー",
            action: #selector(toggleClipboard),
            keyEquivalent: ""
        )
        toggle.target = self
        clipboardToggleItem = toggle
        menu.addItem(toggle)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "設定…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(title: "\(AppInfo.name) について", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "\(AppInfo.name) を終了", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func captureItem(for mode: CaptureMode) -> NSMenuItem {
        let item = NSMenuItem(title: mode.title, action: #selector(captureAction(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = mode.rawValue
        item.image = NSImage(systemSymbolName: mode.symbolName, accessibilityDescription: mode.title)

        if let combo = settingsStore.shortcut(for: mode),
           let key = ShortcutGlyph.keyEquivalent(for: combo) {
            item.keyEquivalent = key
            item.keyEquivalentModifierMask = combo.modifierFlags
        }
        return item
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        clipboardToggleItem?.state = settingsStore.settings.copyToClipboard ? .on : .off
    }

    // MARK: - Actions

    @objc private func captureAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let mode = CaptureMode(rawValue: raw) else { return }
        onCapture?(mode)
    }

    @objc private func toggleClipboard() {
        onToggleClipboard?()
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: AppInfo.name,
            .applicationVersion: "\(AppInfo.version) (\(AppInfo.build))"
        ])
    }

    @objc private func quit() {
        onQuit?()
    }
}

/// Maps a `KeyCombo` to the single-character `keyEquivalent` NSMenu expects, so
/// the menu renders the shortcut glyphs natively.
enum ShortcutGlyph {
    static func keyEquivalent(for combo: KeyCombo) -> String? {
        guard let char = TISKeyTranslator.character(for: combo.keyCode), !char.isEmpty else { return nil }
        return char.lowercased()
    }
}

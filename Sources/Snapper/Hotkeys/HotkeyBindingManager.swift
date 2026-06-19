import Foundation

/// Bridges `SettingsStore` shortcuts to the low-level `HotkeyCenter`,
/// re-registering whenever the bindings change so the two stay in sync.
@MainActor
final class HotkeyBindingManager {
    private let center = HotkeyCenter()
    private let settingsStore: SettingsStore
    private var lastBoundShortcuts: [CaptureMode: KeyCombo] = [:]

    /// Invoked when a bound shortcut fires.
    var onTrigger: ((CaptureMode) -> Void)?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    /// (Re)binds all shortcuts from the current settings. Idempotent — only does
    /// work when the bindings actually changed.
    func refresh() {
        let shortcuts = settingsStore.settings.shortcuts
        guard shortcuts != lastBoundShortcuts else { return }
        lastBoundShortcuts = shortcuts

        center.unregisterAll()
        for mode in CaptureMode.allCases {
            guard let combo = shortcuts[mode], combo.isValid else { continue }
            let didRegister = center.register(combo) { [weak self] in
                self?.onTrigger?(mode)
            }
            if !didRegister {
                AppLog.error("Could not bind \(mode.rawValue) to \(combo.displayString) (already in use?)")
            }
        }
    }
}

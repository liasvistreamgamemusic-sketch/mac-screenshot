import Combine
import Foundation

/// Bridges `SettingsStore` shortcuts to the low-level `HotkeyCenter`,
/// re-registering whenever the bindings change so the two stay in sync.
@MainActor
final class HotkeyBindingManager: ObservableObject {
    private let center = HotkeyCenter()
    private let settingsStore: SettingsStore
    private var lastBoundShortcuts: [CaptureMode: KeyCombo] = [:]

    /// Modes whose shortcut could not be registered (e.g. taken by another app or
    /// the system). Published so the settings UI can warn about a dead shortcut
    /// instead of failing silently.
    @Published private(set) var unboundModes: Set<CaptureMode> = []

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
        var failed: Set<CaptureMode> = []
        for mode in CaptureMode.allCases {
            guard let combo = shortcuts[mode] else { continue } // genuinely unset
            guard combo.isValid else {
                // Present but no longer valid (e.g. a legacy ⌥⇧-only combo).
                AppLog.error("Invalid shortcut for \(mode.rawValue): \(combo.displayString)")
                failed.insert(mode)
                continue
            }
            let didRegister = center.register(combo) { [weak self] in
                self?.onTrigger?(mode)
            }
            if !didRegister {
                AppLog.error("Could not bind \(mode.rawValue) to \(combo.displayString) (already in use?)")
                failed.insert(mode)
            }
        }
        unboundModes = failed
    }
}

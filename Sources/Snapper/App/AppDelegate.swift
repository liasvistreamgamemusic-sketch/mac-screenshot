import AppKit
import Combine

/// Wires the app's subsystems together and owns their lifetimes. Acts as the
/// composition root: nothing else constructs these collaborators.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = SettingsStore()
    private lazy var captureCoordinator = CaptureCoordinator(settingsStore: settingsStore)
    private lazy var hotkeyManager = HotkeyBindingManager(settingsStore: settingsStore)
    private lazy var settingsWindow = SettingsWindowController(store: settingsStore, hotkeys: hotkeyManager)
    private lazy var updater = AppUpdater(settingsStore: settingsStore)
    private var statusItem: StatusItemController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        CaptureFeedback.requestNotificationAuthorizationIfNeeded()

        hotkeyManager.onTrigger = { [weak self] mode in
            self?.captureCoordinator.capture(mode)
        }

        let statusItem = StatusItemController(settingsStore: settingsStore)
        statusItem.onCapture = { [weak self] mode in self?.captureCoordinator.capture(mode) }
        statusItem.onOpenSettings = { [weak self] in
            // Reflect any change made directly in macOS Login Items before showing.
            self?.reconcileLaunchAtLogin()
            self?.settingsWindow.show()
        }
        statusItem.onToggleClipboard = { [weak self] in
            self?.settingsStore.update { $0.copyToClipboard.toggle() }
        }
        statusItem.onQuit = { NSApp.terminate(nil) }
        self.statusItem = statusItem

        // Adopt the real login-item state first so an external change (macOS
        // Login Items) is reflected, not overwritten by the stored value below.
        reconcileLaunchAtLogin()

        // Subscribing emits the current settings synchronously, which performs
        // the initial hotkey binding and login-item sync.
        observeSettings()

        // First-run nudge if the capture permission is missing.
        if !ScreenRecordingPermission.isGranted {
            ScreenRecordingPermission.request()
        }

        scheduleStartupUpdateCheck()
    }

    /// Quietly checks for a newer release shortly after launch, when enabled and
    /// running from a packaged bundle (never during `swift run`).
    private func scheduleStartupUpdateCheck() {
        guard AppInfo.isRunningFromBundle, settingsStore.settings.automaticUpdateChecks else { return }
        Task { [weak self] in
            // Let the app settle before interrupting with any prompt.
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await self?.updater.checkForUpdates(userInitiated: false)
        }
    }

    /// Re-bind hotkeys whenever settings change. The login item is driven
    /// directly by the settings toggle (see `SettingsView`), not from here — a
    /// coarse settings sink can't tell a user toggle from an unrelated change and
    /// would fight the system state.
    private func observeSettings() {
        settingsStore.$settings
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.hotkeyManager.refresh()
            }
            .store(in: &cancellables)
    }

    /// Mirrors the real system login-item state into settings so the toggle
    /// reflects reality — including a change made directly in macOS Login Items.
    /// Pull-only: it never pushes the stored value back to the system.
    private func reconcileLaunchAtLogin() {
        let systemEnabled = LaunchAtLogin.isEnabled
        if settingsStore.settings.launchAtLogin != systemEnabled {
            settingsStore.update { $0.launchAtLogin = systemEnabled }
        }
    }
}

import AppKit
import Combine

/// Wires the app's subsystems together and owns their lifetimes. Acts as the
/// composition root: nothing else constructs these collaborators.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = SettingsStore()
    private lazy var captureCoordinator = CaptureCoordinator(settingsStore: settingsStore)
    private lazy var hotkeyManager = HotkeyBindingManager(settingsStore: settingsStore)
    private lazy var settingsWindow = SettingsWindowController(store: settingsStore)
    private var statusItem: StatusItemController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        CaptureFeedback.requestNotificationAuthorizationIfNeeded()

        hotkeyManager.onTrigger = { [weak self] mode in
            self?.captureCoordinator.capture(mode)
        }

        let statusItem = StatusItemController(settingsStore: settingsStore)
        statusItem.onCapture = { [weak self] mode in self?.captureCoordinator.capture(mode) }
        statusItem.onOpenSettings = { [weak self] in self?.settingsWindow.show() }
        statusItem.onToggleClipboard = { [weak self] in
            self?.settingsStore.update { $0.copyToClipboard.toggle() }
        }
        statusItem.onQuit = { NSApp.terminate(nil) }
        self.statusItem = statusItem

        // Subscribing emits the current settings synchronously, which performs
        // the initial hotkey binding and login-item sync.
        observeSettings()

        // First-run nudge if the capture permission is missing.
        if !ScreenRecordingPermission.isGranted {
            ScreenRecordingPermission.request()
        }
    }

    /// Re-bind hotkeys and login item whenever settings change.
    private func observeSettings() {
        settingsStore.$settings
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.hotkeyManager.refresh()
                self?.syncLaunchAtLogin()
            }
            .store(in: &cancellables)
    }

    private func syncLaunchAtLogin() {
        let desired = settingsStore.settings.launchAtLogin
        if desired != LaunchAtLogin.isEnabled {
            LaunchAtLogin.setEnabled(desired)
        }
    }
}

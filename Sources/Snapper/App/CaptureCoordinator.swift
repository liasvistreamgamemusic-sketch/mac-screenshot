import AppKit

/// Orchestrates a capture from trigger to output: resolves the mode, drives the
/// region overlay when needed, performs the capture, and dispatches outputs.
/// All public methods are main-actor bound because they touch UI.
@MainActor
final class CaptureCoordinator {
    private let settingsStore: SettingsStore
    private let regionController = RegionSelectionController()
    private var isCapturing = false

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    /// Entry point used by both hotkeys and the menu.
    func capture(_ mode: CaptureMode) {
        // Region selection owns its own re-entrancy guard; other modes guard here.
        guard !isCapturing else { return }

        switch mode {
        case .region:
            beginRegionCapture()
        case .activeDisplay, .allDisplays:
            Task { await self.performCapture(mode, region: nil) }
        }
    }

    // MARK: - Region

    private func beginRegionCapture() {
        guard !regionController.isActive else { return }
        regionController.begin { [weak self] rect in
            guard let self else { return }
            guard let rect else { return } // cancelled
            Task {
                // Give the overlay window a moment to leave the screen so it is
                // never captured in the screenshot.
                try? await Task.sleep(nanoseconds: 80_000_000)
                await self.performCapture(.region, region: rect)
            }
        }
    }

    // MARK: - Capture + output

    private func performCapture(_ mode: CaptureMode, region: CGRect?) async {
        isCapturing = true
        defer { isCapturing = false }

        let settings = settingsStore.settings
        let service = ScreenCaptureService()

        do {
            let captured = try await service.capture(mode, region: region)
            let dispatcher = CaptureOutputDispatcher(settings: settings)
            let outcome = try dispatcher.dispatch(captured)
            AppLog.info("Captured \(mode.rawValue): clipboard=\(outcome.copiedToClipboard) file=\(outcome.savedURL?.lastPathComponent ?? "-")")
        } catch let error as CaptureError {
            presentError(error.errorDescription ?? "キャプチャに失敗しました。")
        } catch {
            presentError(error.localizedDescription)
        }
    }

    private func presentError(_ message: String) {
        AppLog.error(message)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "\(AppInfo.name) — キャプチャエラー"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

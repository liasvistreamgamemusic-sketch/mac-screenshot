import AppKit

/// Routes a finished capture to every enabled output (clipboard, file) and
/// fires the configured feedback. Pure side-effect coordinator with no capture
/// logic of its own, so outputs can evolve independently of capture.
@MainActor
struct CaptureOutputDispatcher {
    let settings: AppSettings

    /// Result describing what happened, for logging/notifications.
    struct Outcome {
        var copiedToClipboard = false
        var savedURL: URL?
    }

    @discardableResult
    func dispatch(_ capture: CapturedImage) throws -> Outcome {
        let encoded = try ImageEncoder.encode(
            capture.cgImage,
            format: settings.imageFormat,
            jpegQuality: settings.jpegQuality
        )

        var outcome = Outcome()

        if settings.copyToClipboard {
            ClipboardWriter.write(capture.cgImage, encoded: encoded, format: settings.imageFormat)
            outcome.copiedToClipboard = true
        }

        if settings.saveToFile {
            outcome.savedURL = try ImageFileWriter.write(
                encoded,
                mode: capture.mode,
                format: settings.imageFormat,
                into: settings.resolvedSaveDirectory
            )
        }

        if settings.playSound {
            CaptureFeedback.playShutterSound()
        }

        if settings.showNotification {
            CaptureFeedback.notify(title: notificationTitle(for: outcome), body: notificationBody(for: outcome))
        }

        return outcome
    }

    private func notificationTitle(for outcome: Outcome) -> String {
        outcome.savedURL != nil ? "スクリーンショットを保存しました" : "スクリーンショットを撮影しました"
    }

    private func notificationBody(for outcome: Outcome) -> String {
        var parts: [String] = []
        if outcome.copiedToClipboard { parts.append("クリップボードにコピー済み（貼り付け可能）") }
        if let url = outcome.savedURL { parts.append(url.lastPathComponent) }
        return parts.isEmpty ? "完了しました" : parts.joined(separator: " · ")
    }
}

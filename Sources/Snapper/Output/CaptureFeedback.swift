import AppKit
import UserNotifications

/// User-facing feedback for completed captures: shutter sound and a banner.
@MainActor
enum CaptureFeedback {
    /// Candidate paths for the system screenshot sound, in preference order.
    /// These ship inside the CoreAudio component on macOS.
    private static let shutterSoundPaths = [
        "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Screen Capture.aif",
        "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Grab.aif",
        "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Shutter.aif"
    ]

    /// Lazily-loaded shutter sound, reused across captures.
    private static let shutterSound: NSSound? = {
        for path in shutterSoundPaths where FileManager.default.fileExists(atPath: path) {
            if let sound = NSSound(contentsOfFile: path, byReference: true) { return sound }
        }
        return NSSound(named: NSSound.Name("Pop"))
    }()

    /// Plays the system screenshot shutter sound, mirroring macOS.
    static func playShutterSound() {
        guard let sound = shutterSound else {
            NSSound.beep()
            return
        }
        sound.stop() // allow rapid re-triggering
        sound.play()
    }

    /// Requests notification authorisation once, lazily.
    static func requestNotificationAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                AppLog.error("Notification authorization error: \(error.localizedDescription)")
            } else {
                AppLog.debug("Notification authorization granted: \(granted)")
            }
        }
    }

    /// Posts a banner describing where the capture went.
    static func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                AppLog.error("Failed to post notification: \(error.localizedDescription)")
            }
        }
    }
}

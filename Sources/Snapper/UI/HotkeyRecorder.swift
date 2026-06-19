import AppKit
import SwiftUI

/// A SwiftUI control that records a global shortcut. Clicking it starts
/// listening for the next key combination via a local event monitor; Escape
/// cancels. Only combos with at least one modifier are accepted.
struct HotkeyRecorder: View {
    @Binding var combo: KeyCombo

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: toggle) {
            Text(isRecording ? "キーを入力…" : combo.displayString)
                .font(.system(.body, design: .rounded).monospaced())
                .frame(minWidth: 92)
        }
        .buttonStyle(.bordered)
        .tint(isRecording ? .accentColor : nil)
        .help("クリックして新しいショートカットを記録（Esc でキャンセル）")
        .onDisappear(perform: stop)
    }

    private func toggle() {
        isRecording ? stop() : start()
    }

    private func start() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape cancels
                stop()
                return nil
            }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let candidate = KeyCombo(keyCode: UInt32(event.keyCode), modifierFlags: flags)
            if candidate.isValid {
                combo = candidate
                stop()
            }
            return nil // always consume while recording
        }
    }

    private func stop() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

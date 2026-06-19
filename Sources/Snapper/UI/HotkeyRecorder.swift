import AppKit
import SwiftUI

/// A SwiftUI control that records a global shortcut. Clicking it starts
/// listening for the next key combination via a local event monitor; Escape
/// cancels. Only combos with at least one modifier are accepted.
struct HotkeyRecorder: View {
    @Binding var combo: KeyCombo

    @State private var isRecording = false
    @State private var liveModifiers: NSEvent.ModifierFlags = []
    @State private var monitor: Any?

    var body: some View {
        Button(action: toggle) {
            Text(label)
                .font(.system(.body, design: .rounded).monospaced())
                .frame(minWidth: 92)
        }
        .buttonStyle(.bordered)
        .tint(isRecording ? .accentColor : nil)
        .help("クリックして新しいショートカットを記録（⌘ または ⌃ を含めてください。Esc でキャンセル）")
        .onDisappear(perform: stop)
    }

    /// While recording, show the modifiers held so far so the user can see
    /// exactly what they are about to bind (and catch a wrong key/modifier).
    private var label: String {
        guard isRecording else { return combo.displayString }
        let glyphs = KeyCombo.glyphs(for: liveModifiers)
        return glyphs.isEmpty ? "キーを入力…" : "\(glyphs)…"
    }

    private func toggle() {
        isRecording ? stop() : start()
    }

    private func start() {
        isRecording = true
        liveModifiers = []
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            switch event.type {
            case .flagsChanged:
                liveModifiers = event.modifierFlags.intersection(KeyCombo.relevantModifiers)
            case .keyDown:
                if event.keyCode == 53 { // Escape cancels
                    stop()
                    break
                }
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                let candidate = KeyCombo(keyCode: UInt32(event.keyCode), modifierFlags: flags)
                if candidate.isValid {
                    combo = candidate
                    stop()
                } else {
                    // Needs ⌘ or ⌃ — reject and keep listening so the user can
                    // correct without the wrong combo ever being saved.
                    NSSound.beep()
                }
            default:
                break
            }
            return nil // always consume while recording
        }
    }

    private func stop() {
        isRecording = false
        liveModifiers = []
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

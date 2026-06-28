import AppKit

/// Presents a borderless overlay window on every display and resolves the
/// user's rectangular selection as a Core Graphics (top-left origin) global rect.
///
/// One window per `NSScreen` is used rather than a single window spanning the
/// union of all frames: a lone borderless window cannot reliably render or
/// receive mouse events across multiple displays, which left secondary displays
/// undimmed and unselectable.
@MainActor
final class RegionSelectionController {
    private var windows: [OverlayWindow] = []
    private var completion: ((CGRect?) -> Void)?

    /// Whether a selection session is currently active.
    var isActive: Bool { !windows.isEmpty }

    /// Presents the overlay. `completion` receives the selected rect in CG
    /// global coordinates, or `nil` if cancelled.
    func begin(completion: @escaping (CGRect?) -> Void) {
        guard windows.isEmpty else { return }
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            completion(nil)
            return
        }
        self.completion = completion

        NSApp.activate(ignoringOtherApps: true)

        for screen in screens {
            let frame = screen.frame
            let overlay = makeOverlayWindow(for: frame)

            let view = RegionSelectionView(frame: CGRect(origin: .zero, size: frame.size))
            view.onComplete = { [weak self] rectInView in
                guard let self else { return }
                self.handleSelection(rectInView, windowOrigin: frame.origin)
            }
            overlay.contentView = view

            overlay.orderFrontRegardless()
            overlay.makeFirstResponder(view)
            windows.append(overlay)
        }

        // Make the window on the active screen key so it receives the Escape key.
        let mainScreen = NSScreen.main
        let keyWindow = windows.first { $0.frame == mainScreen?.frame } ?? windows.first
        keyWindow?.makeKey()
    }

    private func makeOverlayWindow(for frame: CGRect) -> OverlayWindow {
        let overlay = OverlayWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        overlay.isOpaque = false
        overlay.backgroundColor = .clear
        overlay.level = .screenSaver
        overlay.ignoresMouseEvents = false
        overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        overlay.hasShadow = false
        return overlay
    }

    private func handleSelection(_ rectInView: CGRect?, windowOrigin: CGPoint) {
        guard let rectInView else {
            finish(with: nil)
            return
        }
        // View coords → Cocoa global (bottom-left) → CG global (top-left).
        let cocoaGlobal = rectInView.offsetBy(dx: windowOrigin.x, dy: windowOrigin.y)
        let cgGlobal = CoordinateConverter.cocoaToCG(cocoaGlobal)
        finish(with: cgGlobal)
    }

    private func finish(with rect: CGRect?) {
        guard let completion else { return }
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        self.completion = nil
        completion(rect)
    }
}

/// Borderless windows cannot become key by default; this subclass opts in so the
/// overlay can receive mouse drags and the Escape key.
private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

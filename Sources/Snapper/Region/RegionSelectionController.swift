import AppKit

/// Presents a borderless overlay window spanning all displays and resolves the
/// user's rectangular selection as a Core Graphics (top-left origin) global rect.
@MainActor
final class RegionSelectionController {
    private var window: OverlayWindow?
    private var completion: ((CGRect?) -> Void)?

    /// Whether a selection session is currently active.
    var isActive: Bool { window != nil }

    /// Presents the overlay. `completion` receives the selected rect in CG
    /// global coordinates, or `nil` if cancelled.
    func begin(completion: @escaping (CGRect?) -> Void) {
        guard window == nil else { return }
        self.completion = completion

        let unionFrame = NSScreen.screens.reduce(CGRect.null) { $0.union($1.frame) }
        guard !unionFrame.isNull else {
            finish(with: nil)
            return
        }

        let overlay = OverlayWindow(
            contentRect: unionFrame,
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

        let view = RegionSelectionView(frame: CGRect(origin: .zero, size: unionFrame.size))
        view.onComplete = { [weak self] rectInView in
            guard let self else { return }
            self.handleSelection(rectInView, windowOrigin: unionFrame.origin)
        }
        overlay.contentView = view

        self.window = overlay

        NSApp.activate(ignoringOtherApps: true)
        overlay.makeKeyAndOrderFront(nil)
        overlay.makeFirstResponder(view)
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
        window?.orderOut(nil)
        window = nil
        let completion = self.completion
        self.completion = nil
        completion?(rect)
    }
}

/// Borderless windows cannot become key by default; this subclass opts in so the
/// overlay can receive mouse drags and the Escape key.
private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

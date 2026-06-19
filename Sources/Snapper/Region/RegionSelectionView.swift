import AppKit

/// Full-overlay view that lets the user drag out a rectangular selection.
/// Dims the screen, punches a clear hole for the live selection, and reports
/// the result in its own (window) coordinate space.
final class RegionSelectionView: NSView {
    /// Called with the selection rect (view coordinates) on mouse-up, or `nil`
    /// if the user cancelled / made an empty selection.
    var onComplete: ((CGRect?) -> Void)?

    private var anchorPoint: CGPoint?
    private var currentRect: CGRect = .zero

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { false }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: CGRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Dim everything.
        context.setFillColor(NSColor.black.withAlphaComponent(0.28).cgColor)
        context.fill(bounds)

        guard currentRect.width > 0, currentRect.height > 0 else { return }

        // Punch a clear hole for the selection.
        context.setBlendMode(.clear)
        context.fill(currentRect)
        context.setBlendMode(.normal)

        // Border.
        context.setStrokeColor(NSColor.controlAccentColor.cgColor)
        context.setLineWidth(1.5)
        context.stroke(currentRect.insetBy(dx: 0.75, dy: 0.75))

        drawDimensionLabel()
    }

    private func drawDimensionLabel() {
        let text = "\(Int(currentRect.width.rounded())) × \(Int(currentRect.height.rounded()))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let padding: CGFloat = 6
        let boxSize = CGSize(width: size.width + padding * 2, height: size.height + padding)

        var origin = CGPoint(x: currentRect.minX, y: currentRect.minY - boxSize.height - 4)
        if origin.y < 0 { origin.y = currentRect.maxY + 4 } // flip below → above edge

        let boxRect = CGRect(origin: origin, size: boxSize)
        let path = NSBezierPath(roundedRect: boxRect, xRadius: 4, yRadius: 4)
        NSColor.black.withAlphaComponent(0.7).setFill()
        path.fill()
        (text as NSString).draw(
            at: CGPoint(x: boxRect.minX + padding, y: boxRect.minY + padding / 2),
            withAttributes: attributes
        )
    }

    // MARK: - Mouse handling

    override func mouseDown(with event: NSEvent) {
        anchorPoint = convert(event.locationInWindow, from: nil)
        currentRect = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let anchor = anchorPoint else { return }
        let point = convert(event.locationInWindow, from: nil)
        currentRect = CGRect(
            x: min(anchor.x, point.x),
            y: min(anchor.y, point.y),
            width: abs(point.x - anchor.x),
            height: abs(point.y - anchor.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            anchorPoint = nil
            currentRect = .zero
            needsDisplay = true
        }
        let result = (currentRect.width >= 1 && currentRect.height >= 1) ? currentRect : nil
        onComplete?(result)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onComplete?(nil)
        } else {
            super.keyDown(with: event)
        }
    }
}

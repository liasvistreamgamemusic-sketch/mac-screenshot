import CoreGraphics
import Foundation
import ScreenCaptureKit

/// Performs the actual screen captures via ScreenCaptureKit's one-shot
/// `SCScreenshotManager`. Stateless and reusable; each call fetches fresh
/// shareable content so newly connected displays are always honoured.
struct ScreenCaptureService {

    /// Whether to render the mouse cursor into the capture.
    var includeCursor: Bool = false

    // MARK: - Public capture entry points

    func capture(_ mode: CaptureMode, region: CGRect? = nil) async throws -> CapturedImage {
        switch mode {
        case .activeDisplay:
            return try await captureActiveDisplay()
        case .allDisplays:
            return try await captureAllDisplays()
        case .region:
            guard let region, region.width >= 1, region.height >= 1 else {
                throw CaptureError.emptySelection
            }
            return try await captureRegion(region)
        }
    }

    // MARK: - Mode implementations

    private func captureActiveDisplay() async throws -> CapturedImage {
        guard let displayID = DisplayResolver.activeDisplayID() else {
            throw CaptureError.noDisplaysAvailable
        }
        let content = try await shareableContent()
        guard let display = content.displays.first(where: { $0.displayID == displayID })
            ?? content.displays.first else {
            throw CaptureError.noDisplaysAvailable
        }
        let image = try await captureFullDisplay(display)
        return CapturedImage(cgImage: image, mode: .activeDisplay, logicalSize: display.frame.size)
    }

    private func captureAllDisplays() async throws -> CapturedImage {
        let composite = try await compositeAllDisplays()
        return CapturedImage(cgImage: composite.image, mode: .allDisplays, logicalSize: composite.bounds.size)
    }

    private func captureRegion(_ region: CGRect) async throws -> CapturedImage {
        let composite = try await compositeAllDisplays()
        // The crop must use the exact scale the composite was rendered at,
        // otherwise points → pixels mapping is off on mixed-DPI setups.
        let cropped = try ImageCompositor.crop(
            composite.image,
            globalRect: region,
            origin: composite.origin,
            scale: composite.scale
        )
        return CapturedImage(cgImage: cropped, mode: .region, logicalSize: region.size)
    }

    // MARK: - Building blocks

    /// Captures every active display and composites them into a single image.
    private func compositeAllDisplays() async throws -> (image: CGImage, origin: CGPoint, bounds: CGRect, scale: CGFloat) {
        let content = try await shareableContent()
        guard !content.displays.isEmpty else { throw CaptureError.noDisplaysAvailable }

        // Composite at the highest scale present so no display loses detail.
        let scale = content.displays
            .map { ScreenScale.factor(for: $0.displayID) }
            .max() ?? 2.0

        var tiles: [ImageCompositor.Tile] = []
        tiles.reserveCapacity(content.displays.count)
        for display in content.displays {
            let image = try await captureFullDisplay(display)
            tiles.append(.init(bounds: display.frame, image: image))
        }

        let result = try ImageCompositor.composite(tiles: tiles, scale: scale)
        let virtualBounds = tiles.reduce(CGRect.null) { $0.union($1.bounds) }
        return (result.image, result.origin, virtualBounds, scale)
    }

    private func captureFullDisplay(_ display: SCDisplay) async throws -> CGImage {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        let pixelSize = ScreenScale.pixelSize(for: display.displayID)
        config.width = pixelSize.width
        config.height = pixelSize.height
        config.captureResolution = .best
        config.showsCursor = includeCursor
        config.ignoreShadowsDisplay = true

        do {
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        } catch {
            throw mapCaptureError(error)
        }
    }

    private func shareableContent() async throws -> SCShareableContent {
        do {
            return try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: false
            )
        } catch {
            throw mapCaptureError(error)
        }
    }

    /// Normalises ScreenCaptureKit errors into our user-facing `CaptureError`.
    private func mapCaptureError(_ error: Error) -> CaptureError {
        let nsError = error as NSError
        // SCStream errors in the user-declined / not-authorised range map to a
        // missing Screen Recording permission, which is by far the most common
        // real-world failure.
        if nsError.domain == SCStreamError.errorDomain {
            AppLog.error("ScreenCaptureKit error \(nsError.code): \(nsError.localizedDescription)")
            return .permissionDenied
        }
        AppLog.error("Capture failed: \(error.localizedDescription)")
        return .permissionDenied
    }
}

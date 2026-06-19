import AppKit

/// Writes a captured image to the general pasteboard so it can be pasted
/// immediately. This is the app's default, headline behaviour.
enum ClipboardWriter {
    /// Places the image on the pasteboard as a single item carrying several
    /// representations (the chosen format, plus TIFF and PNG), maximising
    /// compatibility with paste targets such as editors, chat and design apps.
    static func write(_ image: CGImage, encoded: Data, format: ImageFormat) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let item = NSPasteboardItem()
        item.setData(encoded, forType: NSPasteboard.PasteboardType(format.utType.identifier))

        let rep = NSBitmapImageRep(cgImage: image)
        if let tiff = rep.tiffRepresentation {
            item.setData(tiff, forType: .tiff)
        }
        if format != .png, let png = try? ImageEncoder.encode(image, format: .png, jpegQuality: 1.0) {
            item.setData(png, forType: .png)
        }

        pasteboard.writeObjects([item])
    }
}

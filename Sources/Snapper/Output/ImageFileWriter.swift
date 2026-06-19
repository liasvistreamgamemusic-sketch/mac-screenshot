import Foundation

/// Persists encoded image data to disk using a Finder-style timestamped name.
enum ImageFileWriter {
    /// Writes `data` into `directory`, returning the resulting file URL.
    /// Creates the directory if it does not yet exist and de-duplicates names.
    static func write(_ data: Data, mode: CaptureMode, format: ImageFormat, into directory: URL) throws -> URL {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        let baseName = fileName(for: mode, format: format)
        var candidate = directory.appendingPathComponent(baseName)
        var counter = 2
        while fileManager.fileExists(atPath: candidate.path) {
            let stem = (baseName as NSString).deletingPathExtension
            let suffix = "\(stem) (\(counter)).\(format.fileExtension)"
            candidate = directory.appendingPathComponent(suffix)
            counter += 1
        }

        try data.write(to: candidate, options: .atomic)
        return candidate
    }

    private static func fileName(for mode: CaptureMode, format: ImageFormat) -> String {
        "Snapper \(mode.fileNameToken) \(timestamp()).\(format.fileExtension)"
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return formatter.string(from: Date())
    }
}

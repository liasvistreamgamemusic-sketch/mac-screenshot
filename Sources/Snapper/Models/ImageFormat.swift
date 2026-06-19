import Foundation
import UniformTypeIdentifiers

/// Output encodings supported for files saved to disk.
enum ImageFormat: String, CaseIterable, Codable, Identifiable, Sendable {
    case png
    case jpeg

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .png: return "PNG (可逆)"
        case .jpeg: return "JPEG (圧縮)"
        }
    }

    var fileExtension: String { rawValue }

    var utType: UTType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        }
    }
}

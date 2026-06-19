import CoreGraphics
import Foundation

/// Immutable result of a successful capture.
struct CapturedImage: Sendable {
    let cgImage: CGImage
    let mode: CaptureMode
    /// Point size of the captured area (logical, not pixels).
    let logicalSize: CGSize

    var pixelWidth: Int { cgImage.width }
    var pixelHeight: Int { cgImage.height }
}

/// Errors surfaced to the user when a capture cannot complete.
enum CaptureError: LocalizedError {
    case noDisplaysAvailable
    case permissionDenied
    case emptySelection
    case compositingFailed
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .noDisplaysAvailable:
            return "利用可能なディスプレイが見つかりませんでした。"
        case .permissionDenied:
            return "画面収録の権限がありません。システム設定 > プライバシーとセキュリティ > 画面収録 で Snapper を許可してください。"
        case .emptySelection:
            return "選択領域が空です。"
        case .compositingFailed:
            return "画像の合成に失敗しました。"
        case .encodingFailed:
            return "画像のエンコードに失敗しました。"
        }
    }
}

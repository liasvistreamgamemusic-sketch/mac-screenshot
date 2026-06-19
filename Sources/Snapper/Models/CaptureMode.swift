import Foundation

/// The three capture strategies the app exposes. Designed as a closed enum so
/// adding a new mode forces every switch in the codebase to be updated.
enum CaptureMode: String, CaseIterable, Codable, Identifiable, Sendable {
    /// Interactive rectangular region selection across displays.
    case region
    /// The active (frontmost) window, captured on its own — transparent
    /// background, no surrounding desktop.
    case window
    /// The full display that currently contains the frontmost window
    /// (falls back to the display under the cursor, then the main display).
    case activeDisplay
    /// Every connected display stitched into a single image laid out to match
    /// the physical arrangement in System Settings.
    case allDisplays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .region: return "選択領域をキャプチャ"
        case .window: return "アクティブなウィンドウをキャプチャ"
        case .activeDisplay: return "アクティブな画面をキャプチャ"
        case .allDisplays: return "全画面をまとめてキャプチャ"
        }
    }

    /// SF Symbol used in menus and the status bar submenu.
    var symbolName: String {
        switch self {
        case .region: return "selection.pin.in.out"
        case .window: return "macwindow.on.rectangle"
        case .activeDisplay: return "macwindow"
        case .allDisplays: return "rectangle.3.group"
        }
    }

    /// Short token used inside saved file names.
    var fileNameToken: String {
        switch self {
        case .region: return "Region"
        case .window: return "Window"
        case .activeDisplay: return "Display"
        case .allDisplays: return "AllDisplays"
        }
    }
}

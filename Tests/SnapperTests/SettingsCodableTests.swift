import XCTest
@testable import Snapper

final class SettingsCodableTests: XCTestCase {
    func testDefaultSettingsRoundTrip() throws {
        let original = AppSettings.default
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testDefaultsHaveAShortcutForEveryMode() {
        for mode in CaptureMode.allCases {
            XCTAssertNotNil(AppSettings.default.shortcuts[mode], "Missing default shortcut for \(mode)")
            XCTAssertTrue(AppSettings.default.shortcuts[mode]!.isValid)
        }
    }

    func testClipboardOnByDefault() {
        XCTAssertTrue(AppSettings.default.copyToClipboard)
    }
}

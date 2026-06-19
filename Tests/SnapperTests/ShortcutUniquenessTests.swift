import XCTest
@testable import Snapper

final class ShortcutUniquenessTests: XCTestCase {
    func testDefaultsAreAllDistinct() {
        // Every default mode must own a combo no other mode uses — otherwise one
        // would silently fail to register.
        let settings = AppSettings.default
        for mode in CaptureMode.allCases {
            let combo = settings.shortcuts[mode]!
            XCTAssertNil(
                settings.mode(using: combo, excluding: mode),
                "\(mode) shares its shortcut with another mode"
            )
        }
    }

    func testDetectsTheModeAlreadyUsingACombo() {
        let settings = AppSettings.default
        let regionCombo = settings.shortcuts[.region]!
        // Asking which *other* mode uses region's combo finds region itself.
        XCTAssertEqual(settings.mode(using: regionCombo, excluding: .window), .region)
        // Excluding region (its true owner) reports no conflict.
        XCTAssertNil(settings.mode(using: regionCombo, excluding: .region))
    }

    func testDetectsAnIntroducedDuplicate() {
        var settings = AppSettings.default
        // Force window to share region's combo, as a buggy assignment would.
        settings.shortcuts[.window] = settings.shortcuts[.region]
        XCTAssertEqual(settings.mode(using: settings.shortcuts[.region]!, excluding: .region), .window)
    }
}

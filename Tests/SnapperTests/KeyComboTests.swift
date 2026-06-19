import AppKit
import Carbon.HIToolbox
import XCTest
@testable import Snapper

final class KeyComboTests: XCTestCase {
    func testRequiresModifier() {
        let noModifier = KeyCombo(keyCode: UInt32(kVK_ANSI_R), modifierFlags: [])
        XCTAssertFalse(noModifier.isValid)

        let withModifier = KeyCombo(keyCode: UInt32(kVK_ANSI_R), modifierFlags: [.command])
        XCTAssertTrue(withModifier.isValid)
    }

    func testDisplayStringOrdersModifiers() {
        let combo = KeyCombo(keyCode: UInt32(kVK_ANSI_R), modifierFlags: [.control, .option, .command])
        let display = combo.displayString
        XCTAssertTrue(display.hasPrefix("⌃⌥⌘"), "Unexpected order: \(display)")
        XCTAssertTrue(display.hasSuffix("R"))
    }

    func testModifierFlagsAreNormalised() {
        // Caps lock and other non-device-independent flags must be stripped.
        let combo = KeyCombo(keyCode: 0, modifierFlags: [.command, .capsLock])
        XCTAssertFalse(combo.modifierFlags.contains(.capsLock))
        XCTAssertTrue(combo.modifierFlags.contains(.command))
    }
}

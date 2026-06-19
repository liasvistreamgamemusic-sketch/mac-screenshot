import AppKit
import Carbon.HIToolbox
import XCTest
@testable import Snapper

final class KeyComboTests: XCTestCase {
    func testValidityRequiresCommandOrControl() {
        // No modifiers, or only Option/Shift, is rejected: such global hotkeys are
        // unreliable and easily mis-recorded (e.g. ⌥⇧A instead of ⌃⌥S).
        XCTAssertFalse(KeyCombo(keyCode: UInt32(kVK_ANSI_R), modifierFlags: []).isValid)
        XCTAssertFalse(KeyCombo(keyCode: UInt32(kVK_ANSI_A), modifierFlags: [.option, .shift]).isValid)
        XCTAssertFalse(KeyCombo(keyCode: UInt32(kVK_ANSI_R), modifierFlags: [.shift]).isValid)

        // Command or Control (alone or combined) is accepted.
        XCTAssertTrue(KeyCombo(keyCode: UInt32(kVK_ANSI_R), modifierFlags: [.command]).isValid)
        XCTAssertTrue(KeyCombo(keyCode: UInt32(kVK_ANSI_S), modifierFlags: [.control, .option]).isValid)
        XCTAssertTrue(KeyCombo(keyCode: UInt32(kVK_ANSI_R), modifierFlags: [.control, .option, .command]).isValid)
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

import XCTest
@testable import Snapper

final class SemanticVersionTests: XCTestCase {
    func testParsesPlainVersion() {
        let v = SemanticVersion("1.2.3")
        XCTAssertEqual(v, SemanticVersion(major: 1, minor: 2, patch: 3))
    }

    func testParsesLeadingVAndDefaultsMissingComponents() {
        XCTAssertEqual(SemanticVersion("v2"), SemanticVersion(major: 2, minor: 0, patch: 0))
        XCTAssertEqual(SemanticVersion("v1.4"), SemanticVersion(major: 1, minor: 4, patch: 0))
    }

    func testDiscardsPreReleaseAndBuildMetadata() {
        XCTAssertEqual(SemanticVersion("1.2.3-beta.1"), SemanticVersion(major: 1, minor: 2, patch: 3))
        XCTAssertEqual(SemanticVersion("1.2.3+build.7"), SemanticVersion(major: 1, minor: 2, patch: 3))
    }

    func testRejectsNonNumericLeadingComponent() {
        XCTAssertNil(SemanticVersion("latest"))
        XCTAssertNil(SemanticVersion("v.1"))
    }

    func testOrdering() {
        XCTAssertLessThan(SemanticVersion("1.0.0")!, SemanticVersion("1.0.1")!)
        XCTAssertLessThan(SemanticVersion("1.9.0")!, SemanticVersion("1.10.0")!)
        XCTAssertLessThan(SemanticVersion("0.1.0")!, SemanticVersion("1.0.0")!)
        XCTAssertGreaterThan(SemanticVersion("2.0.0")!, SemanticVersion("1.99.99")!)
    }

    func testDevelopmentVersionIsLowerThanAnyRelease() {
        // The `swift run` fallback ("0.0.0-dev") must never look newer than a tag.
        let dev = SemanticVersion(AppInfo.developmentVersion)!
        XCTAssertLessThan(dev, SemanticVersion("0.1.0")!)
    }

    func testDescriptionRoundTrips() {
        XCTAssertEqual(SemanticVersion("1.2.3")!.description, "1.2.3")
    }
}

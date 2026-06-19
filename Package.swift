// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Snapper",
    platforms: [
        .macOS(.v14) // ScreenCaptureKit's SCScreenshotManager requires macOS 14+
    ],
    products: [
        .executable(name: "Snapper", targets: ["Snapper"])
    ],
    targets: [
        .executableTarget(
            name: "Snapper",
            path: "Sources/Snapper",
            swiftSettings: [
                // Pragmatic language mode: Carbon C-callbacks and AppKit delegate
                // patterns interoperate far more cleanly under the v5 model while we
                // still compile with the Swift 6.2 toolchain.
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "SnapperTests",
            dependencies: ["Snapper"],
            path: "Tests/SnapperTests"
        )
    ]
)

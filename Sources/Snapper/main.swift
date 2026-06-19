import AppKit

// Manual application bootstrap (rather than @main) so the executable works
// identically whether launched from an .app bundle or via `swift run`.
// Top-level code runs on the main thread; assert that to construct the
// main-actor-isolated delegate and run the loop.
MainActor.assumeIsolated {
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.delegate = delegate // NSApplication holds the delegate weakly…

    // Menu bar utility: no Dock icon, no main window.
    application.setActivationPolicy(.accessory)

    // …so `delegate` must outlive this call; `run()` blocks until termination,
    // keeping it alive for the whole app lifetime.
    application.run()
    _ = delegate
}

# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project adheres to
[Semantic Versioning](https://semver.org/).

## [0.1.4] - 2026-06-29

### Fixed
- Region selection ignored the built-in display when an external monitor was
  connected: only the external screen dimmed and accepted a selection, while the
  main display stayed bright and unselectable. The overlay used a single
  borderless window spanning the union of all screen frames, which macOS does not
  reliably render or route mouse events for across multiple displays. The overlay
  now uses one window per `NSScreen`, so every display dims and can be selected.

## [0.1.3] - 2026-06-20

### Fixed
- Launch-at-login could not be turned off and re-enabling appeared to drop it
  from macOS Login Items. The cause was the `.requiresApproval` state (after the
  item is disabled in System Settings, macOS will not silently re-enable it):
  the old code only unregistered when the status was exactly `.enabled`, so a
  `.requiresApproval` item lingered. Turning it off now always unregisters, the
  toggle reflects the real `SMAppService` state, and when macOS requires approval
  the settings screen says so and offers a button to open Login Items.

## [0.1.2] - 2026-06-20

### Fixed
- Shortcut recorder could capture an unintended combo (e.g. ⌥⇧A instead of the
  intended ⌃⌥S), leaving that shortcut unresponsive. The recorder now shows the
  modifiers live as you hold them and only accepts combos that include ⌘ or ⌃
  (Option/Shift-only combos are unreliable and easily mis-recorded).
- Launch-at-login now stays consistent with macOS Login Items: a change made in
  System Settings is adopted on launch / when opening Snapper's settings, instead
  of being overwritten by the app's stored value (which made the two diverge).

### Added
- Shortcut settings show a warning on any mode whose stored shortcut is no longer
  valid, in addition to ones that fail to register.

## [0.1.1] - 2026-06-20

### Fixed
- Shortcuts: assigning the same key combination to two capture modes made one of
  them silently stop working (Carbon rejects the duplicate registration, so the
  "other" mode fired instead). Duplicate assignments are now rejected with a
  message naming the conflicting mode.

### Added
- Shortcuts settings: a warning icon on any mode whose shortcut could not be
  registered (e.g. taken by another app or the system), and a "Reset to defaults"
  button.

### Changed
- Build: `scripts/build_app.sh` accepts `BUNDLE_ID` / `DISPLAY_NAME` /
  `BUNDLE_FILENAME` overrides so a local build can use a separate identity
  (e.g. `Snapper Dev`) and not collide with the installed release's Screen
  Recording permission. Default output is unchanged.

## [0.1.0] - 2026-06-19

### Added
- Menu bar (status bar) app for Apple Silicon, no Dock icon.
- Four capture modes via global shortcuts:
  - Region selection (drag a rectangle, spans multiple displays).
  - Active window (the frontmost window, captured on its own with a transparent background).
  - Active display (the display containing the frontmost window).
  - All displays composited into a single image.
- Copy-to-clipboard on capture, enabled by default and toggleable.
- File saving with configurable directory, PNG/JPEG format and JPEG quality.
  Defaults to a dedicated `~/Pictures/Snapper` folder, created on first save.
- In-app auto-update: checks GitHub Releases on launch and installs a newer
  DMG in place (relaunching), with a guided fallback. Toggleable.
- Shutter sound and notification feedback (toggleable).
- Configurable global shortcuts with an in-app recorder.
- Launch-at-login support.
- Settings window accessible from the menu bar header.
- DMG packaging and ad-hoc code signing.

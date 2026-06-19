# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project adheres to
[Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-06-19

### Added
- Menu bar (status bar) app for Apple Silicon, no Dock icon.
- Three capture modes via global shortcuts:
  - Region selection (drag a rectangle, spans multiple displays).
  - Active display (the display containing the frontmost window).
  - All displays composited into a single image.
- Copy-to-clipboard on capture, enabled by default and toggleable.
- File saving with configurable directory, PNG/JPEG format and JPEG quality.
- Shutter sound and notification feedback (toggleable).
- Configurable global shortcuts with an in-app recorder.
- Launch-at-login support.
- Settings window accessible from the menu bar header.
- DMG packaging and ad-hoc code signing.

# Changelog

All notable changes to this project will be documented in this file.

The format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project uses Semantic Versioning.

## [Unreleased]

## [1.2.0] - 2026-10-20

### Added

- Native macOS screenshot thumbnails and their markup, drag-and-drop, copy, delete and save actions for inverted screenshots.
- A native shortcut settings panel with recording, persistence, restore default and conflict feedback. The base shortcut requires Command; Control is reserved for copying.
- Copy-to-clipboard capture through either Control with the shortcut or Control held when completing a selection.
- Recovery of the latest inverted screenshot with Copy, Save As and Discard. Keep one result for up to 24 hours, including across app restarts.
- An independent native screenshot compatibility probe and checks for inversion, transparency, DPI, recovery and Carbon shortcut registration.

### Changed

- Reworked capture into native interactive selection/window capture, background Core Image RGB inversion and handoff to the system screenshot service. Native screenshot destination and thumbnail preferences apply.
- Replaced global event monitoring with Carbon hotkeys. Keep the default shortcut `⌘⇧6` and register a matching Control variant.
- Preserve alpha, pixel dimensions and DPI in SDR PNG output. Read actual capture region, scale and display metadata instead of supplying fixed values.
- Serialize capture tasks and use a separate temporary directory for each capture. Clean up original images after use.
- Request Screen Recording permission only. Remove Accessibility and notification permission requests, custom preview handling and success notifications.
- Localize the language submenu title as “Language” or “语言” according to the selected interface language.
- Lower the deployment target from macOS 26 to macOS 12 and explicitly target Apple Silicon (arm64).

### Fixed

- Preserve existing clipboard content when a capture is cancelled, and avoid overwriting clipboard content changed during image processing.
- Keep the old shortcut registered if a replacement conflicts with another registration.
- Allow a user-initiated native capture attempt when the permission preflight does not confirm access. Document renewal of stale Screen Recording permission entries and launching the correct app copy.
- Treat native handoff as submitted, failed or uncertain rather than claiming that transport submission confirms a saved screenshot. Do not retry ambiguous interruptions or create duplicate captures.

### Distribution Notes

- This checkout prepares 1.2.0 (build 2); it has not yet been published. Local prerelease artifacts use Apple Development signing, not Developer ID distribution signing, and are not notarized. Gatekeeper may block first launch on another Mac.
- macOS 12–26 compatibility is inferred from public API availability and build checks. Interactive validation was performed on macOS 27.2 (26B5112a), Apple Silicon, with an internal 2× display. Older systems, external displays and mixed scales remain unverified; no Intel artifact is provided.
- Native thumbnail handoff depends on the undocumented `com.apple.screencaptureui` service and capture metadata. Compatibility may change independently of public APIs. App Sandbox is disabled; Hardened Runtime and library validation remain enabled.
- See the [validation record](Experiments/NativeScreenshotBridge/README.md) and [release checklist](docs/RELEASE.md) for acceptance results and remaining checks. HDR inversion, screen recording and a full-screen capture entry point are outside this release.

## [1.1.1] - 2025-10-23

### Changed

- Provide a macOS-style named temporary PNG file URL alongside PNG and TIFF clipboard representations for compatibility with receiving applications. Remove the temporary file after five seconds.

## [1.1.0] - 2025-10-23

### Added

- English interface strings and a Chinese/English language menu, with the selected language saved across launches.
- Localized capture, permission and notification messages.

## [1.0.0] - 2025-10-22

### Added

- A menu bar screenshot inverter with no main window or Dock icon.
- Global `⌘⇧6` capture through an event tap, native interactive region selection, pixel-by-pixel RGB inversion and PNG clipboard output.
- Screen Recording and Accessibility permission guidance, completion notifications, and capture, permission-check and quit menu actions.

### Historical Notes

- Versions 1.0.0–1.1.1 are reconstructed from repository history; no version tags exist in the local repository. Dates follow commit timestamps in Asia/Shanghai. Relevant implementation commits: `12ba103` (initial workflow), `2d196ee` (language switching), and `b1d589e` (clipboard file representations). The 1.1.1 change adds clipboard representations and a filename; it does not add embedded PNG metadata.

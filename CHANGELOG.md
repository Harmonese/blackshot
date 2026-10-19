# Changelog

All notable changes to this project will be documented in this file.

The format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project uses Semantic Versioning.

## [Unreleased]

## [1.2.1] - 2026-10-20

### Added

- An editable SVG source for the existing icon design and a generator that renders every PNG size directly from that source.
- Shared `AGENTS.md` development guidance, migrated from the local Claude-specific guide, including documentation and repository-scope conventions.

### Changed

- Regenerate the README image and all macOS app icon PNGs from the vector source, preserving the asset catalog's existing filenames and size mappings.
- Keep local experiments, editor preferences and release working notes out of the repository. Restore the original bilingual README layout with current feature and installation details.

### Distribution Notes

- Version 1.2.1 (build 3) retains the macOS 12+ Apple Silicon target and the same screenshot implementation as 1.2.0. Only macOS 27.2 has interactive validation evidence; older systems and external/mixed-scale displays remain unverified.
- Local release candidates use Apple Development signing and are not notarized. The undocumented native screenshot integration and distribution limitations described under 1.2.0 still apply.

## [1.2.0] - 2026-10-20

### Added

- Native macOS screenshot thumbnails and their markup, drag-and-drop, copy, delete and save actions for inverted screenshots.
- A native shortcut settings panel with recording, persistence, restore default and conflict feedback. The base shortcut requires Command; Control is reserved for copying.
- Copy-to-clipboard capture through either Control with the shortcut or Control held when completing a selection.
- Recovery of the latest inverted screenshot with Copy, Save As and Discard. Keep one result for up to 24 hours, including across app restarts.

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

- Version 1.2.0 (build 2) artifacts use Apple Development signing, not Developer ID distribution signing, and are not notarized. Gatekeeper may block first launch on another Mac.
- macOS 12–26 compatibility is inferred from public API availability and build checks. Interactive validation was performed on macOS 27.2 (26B5112a), Apple Silicon, with an internal 2× display. Older systems, external displays and mixed scales remain unverified; no Intel artifact is provided.
- Native thumbnail handoff depends on the undocumented `com.apple.screencaptureui` service and capture metadata. Compatibility may change independently of public APIs. App Sandbox is disabled; Hardened Runtime and library validation remain enabled.
- HDR inversion, screen recording and a full-screen capture entry point are outside this release.

## [1.1.1] - 2025-10-22

### Fixed
- PNG files copied to clipboard had no metadata; named the copied file using macOS default screenshot filename format.

## [1.1.0] - 2025-10-22

### Added
- English localization support with a language switch menu option (中文 / English).

### Fixed
- Known bugs from the initial release.

## [1.0.0] - 2025-10-22

### Added
- Initial release of Blackshot — a macOS menu bar utility for taking screenshots and automatically inverting their colors.
- Global hotkey `⌘⇧6` via CoreGraphics event tap.
- Pixel-by-pixel color inversion of captured screenshots.
- Clipboard integration with PNG, TIFF, and fileURL format support.
- System notification on successful capture.
- Status bar menu with capture trigger, permission check, and quit options.
- Accessibility and Screen Recording permission checking and prompting.

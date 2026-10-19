# Blackshot development guide

Pure Apple-framework macOS menu bar app. Minimum build target macOS 12, arm64 only; macOS 12–26 compatibility is inferred, not runtime-verified; native screenshot transport has been exercised only on macOS 27.2 (26B5112a). Do not infer compatibility from a successful build.

## Build

```sh
xcodebuild -project Blackshot.xcodeproj -scheme Blackshot -configuration Debug -destination 'platform=macOS' build
xcodebuild -project Blackshot.xcodeproj -scheme Blackshot -configuration Release -destination 'platform=macOS' build
```

Use the existing signing team and a locally available Apple Development identity. A stale CoreSimulator installation can print diagnostics even when the macOS build succeeds: inspect the actual macOS build result. No external dependencies.

For personal interactive acceptance, launch the signed app at `build/Blackshot.app` by its explicit path. Older copies with the same bundle identifier may remain in DerivedData and resolve from Spotlight or the permission list. If permission is enabled but capture fails, verify the running executable path and the permission item's Show in Finder destination; ask the user to remove the stale entry and add the current app. Never reset unrelated privacy permissions. Avoid rebuilding/replacing the binary while the user is granting access or validating it.

## Architecture

- `BlackshotApp` declares the AppDelegate and an empty Settings scene. `AppDelegate` owns one reusable NSStatusItem and the menu. No app activation or permission prompts on normal startup; no success notifications.
- `HotkeyTap` registers a pair of exclusive Carbon hotkeys: base capture and base+Control. Register replacements before removing existing hotkeys. Preferences: `ScreenshotShortcut.v1`. The native settings panel records local key events, requires Command, reserves Control for copying, and can restore default ⌘⇧6.
- `NativeCaptureService` runs `/usr/sbin/screencapture -i -t png` into a unique temporary directory, with `-c` only for an explicit clipboard shortcut. It never clears the clipboard before capture. Do not gate user-initiated capture on CGPreflightScreenCaptureAccess: the native tool must attempt its normal authorized capture path; use preflight only as a diagnostic after failure or in the manual permission menu. Control at mouse release may redirect output to the clipboard; require a changed pasteboard and the system Screenshot EXIF marker before accepting that branch. Do not overwrite clipboard content that changed during inversion.
- `CaptureMetadata` reads native extended attributes for capture region/type, ImageIO DPI, and the intersecting display. No fabricated main-screen coordinates or fixed scale on real captures. Clipboard-only captures do not require a region.
- `ImageInverter` uses CIColorInvert with unmanaged working color space to invert encoded RGB samples, retaining alpha, dimensions and DPI in an 8-bit SDR PNG. Keep tests for semi-transparent pixels.
- `ScreenshotManager` serializes selecting → processing → submitting, then returns to idle independently of native thumbnail lifetime. CPU/image processing is off-main. Cancellation and errors are distinct results; termination cancels active capture and unlinks its directory.
- `NativeScreenshotBridge.m` is the only production owner of private XPC wire keys. Swift uses the bridging header. A transport submission is not a native UI/save acknowledgement. Never blindly retry an interrupted/uncertain submission.
- `RecoveryStore` retains only `Application Support/Blackshot/Recovery/latest.png`, plus an in-memory result when disk writing fails. Replace atomically, expire after 24 hours, provide explicit copy/save/discard. No history or backup directory.
- `LanguageManager` preserves `AppLanguage` with `zh-Hans` / `en`. UI copy is selected through `L` on the main actor.
  The language submenu title follows the current UI language (语言 / Language); do not concatenate language names into the title when adding translations.

## Validation and constraints

Local-only validation tools may be available under `Experiments/NativeScreenshotBridge/`; they are intentionally ignored and are not a prerequisite for a fresh checkout. If present, `./Experiments/NativeScreenshotBridge/validate.sh --self-test` checks pixels, alpha, DPI, invalid data, recovery and shortcut encoding. Keep experimental probes out of the tracked application source.

Signed sandbox testing returned XPC Connection invalid. App Sandbox is disabled; Hardened Runtime and library validation remain enabled. No private entitlements, process injection or security bypasses. Release disables base development-entitlement injection.

Do not implement a lookalike screenshot preview, add a main window, request Accessibility/notification permission, or automatically copy ordinary screenshots. Respect native screenshot destination and thumbnail preferences. HDR, recording and full-screen capture entry points are outside this version.

The unused CoreData model and stale empty test targets originate in the Xcode template; the local standalone validator provides independent checks when available. Do not claim automated interactive acceptance from a successful build.

Local release preparation notes may be available at `docs/RELEASE.md` (ignored, not included in fresh checkouts). App version is 1.2.1, build 3. Do not describe Apple Development signing as Developer ID distribution or notarization.

## Documentation and repository scope

Preserve the existing bilingual README layout, headings, badges and section order. Update only the content required by a feature change; do not redesign or replace the README without an explicit request. Experiments/, .vscode/ and docs/RELEASE.md are local-only and must stay ignored. Stage intended paths explicitly, and preserve remote edits when synchronizing.

## Icon assets

`icon.svg` is the editable vector source. Regenerate `icon.png` and all PNGs named by `Blackshot/Assets.xcassets/AppIcon.appiconset/Contents.json` with `python3 scripts/generate-icons.py`. This development command uses Python 3.9+ and `rsvg-convert` from librsvg; they are not app runtime dependencies. Render each pixel size directly from the SVG, keep the existing filenames and asset-catalog mapping, and do not hand-edit generated PNGs. The menu bar uses a separate system template symbol. Preserve the existing icon design unless a redesign is explicitly requested.

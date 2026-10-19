# Release preparation

This checkout prepares **Blackshot 1.2.0, build 2**, for **macOS 12 or newer on Apple Silicon (arm64)**. The bundle identifier remains `blackshot.Blackshot`.

## Compatibility and distribution

The minimum deployment target is 12.0 in Debug and Release. Compatibility with macOS 12–26 is inferred from API availability and successful builds, not runtime testing. Native screenshot handoff uses an undocumented XPC service and native metadata attributes; older versions may require protocol adjustments. Only macOS 27.2 (26B5112a), with an internal 2× display, has interactive acceptance evidence. Intel builds are not provided.

Local prerelease artifacts use the existing Apple Development identity. This is not Developer ID distribution signing or Apple notarization. Gatekeeper may block first launch on another Mac. Keep this limitation in any prerelease notes; do not disable system-wide security protections. For ordinary public distribution, prepare a Developer ID Application signature and notarization when the required credentials are available.

App Sandbox is disabled because the signed sandbox probe could not reach the native screenshot service. Hardened Runtime and library validation remain enabled. Release does not include `get-task-allow`.

## Build and check

Use a locally available Apple Development identity belonging to the project's existing team. The signing identity may be supplied as a build argument when automatic signing is unavailable:

```sh
export BLACKSHOT_SIGNING_IDENTITY='Apple Development: your local identity'
xcodebuild -project Blackshot.xcodeproj -scheme Blackshot -configuration Debug -destination 'platform=macOS' -derivedDataPath build/ReleasePreparation CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$BLACKSHOT_SIGNING_IDENTITY" build
xcodebuild -project Blackshot.xcodeproj -scheme Blackshot -configuration Release -destination 'platform=macOS' -derivedDataPath build/ReleasePreparation CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$BLACKSHOT_SIGNING_IDENTITY" build
./Experiments/NativeScreenshotBridge/validate.sh --self-test
```

Before packaging, inspect `build/ReleasePreparation/Build/Products/Release/Blackshot.app`:

- `CFBundleShortVersionString`: `1.2.0`; `CFBundleVersion`: `2`.
- `CFBundleIdentifier`: `blackshot.Blackshot`; `LSMinimumSystemVersion`: `12.0`; `LSUIElement`: true.
- The executable contains only arm64 and its Mach-O minimum OS is 12.0.
- `codesign --verify --deep --strict` succeeds; Hardened Runtime is present and sandbox/debug entitlements are absent.
- Debug and Release builds and the independent self-tests pass. The empty template test targets do not substitute for those self-tests or interactive acceptance.

Do not overwrite a running app. Keep one explicit installation path during Screen Recording authorization and interactive acceptance. Old copies under Xcode DerivedData may resolve through search or the permission list. If an enabled permission entry still fails, use Show in Finder to check its destination, then remove that entry and add the current app. Do not reset unrelated privacy permissions.

## Local package

The prepared local outputs are:

- `build/releases/Blackshot-1.2.0-macos-arm64.zip`
- `build/releases/Blackshot-1.2.0-macos-arm64.zip.sha256`
- `build/releases/Blackshot-1.2.0-validation.txt`

The ZIP contains `Blackshot.app`. It is a local prerelease package, not a published download. Generated artifacts remain outside Git. To recreate the package after building:

```sh
mkdir -p build/releases
ditto -c -k --sequesterRsrc --keepParent build/ReleasePreparation/Build/Products/Release/Blackshot.app build/releases/Blackshot-1.2.0-macos-arm64.zip
(cd build/releases && shasum -a 256 Blackshot-1.2.0-macos-arm64.zip > Blackshot-1.2.0-macos-arm64.zip.sha256)
```

Extract the ZIP into a new temporary directory, recheck the extracted app's signature and metadata, and verify its checksum. Do not package Debug products, DerivedData, recovery images or developer credentials.

## Acceptance status

Interactive results are recorded in [the native screenshot validation record](../Experiments/NativeScreenshotBridge/README.md).

Completed on macOS 27.2:

- Default shortcut → system selection → inverted native thumbnail in the signed application, including the final 1.2.0 (build 2) macOS-12-targeted Release build on 2026-10-20.
- Esc cancellation preserves the clipboard; both Control copy workflows produce inverted images.
- Shortcut editing, persistence across restart and restore default; latest-image recovery copying.
- Native markup/save, window/shadow drag-and-drop, right-click copy and delete through signed probes. Right-click copy matched the submitted image pixel-for-pixel.
- Automated RGB/alpha/DPI, corrupt input, recovery replacement/expiry/restart and actual Carbon shortcut conflict rollback checks.

Still pending:

- Runtime feedback from macOS 12–26, external displays and mixed display scales.
- Repeated triggering during selection/processing and capture while an earlier thumbnail is visible.
- Option without window shadow, native save-location changes and the thumbnail-off preference in the production app.
- Recovery Save As/Discard and a conflicting shortcut through the production settings panel; underlying storage and Carbon conflict handling already have independent checks.
- Public distribution signing/notarization if required for the intended release channel.

## Publish

Review the 1.2.0 entry in [CHANGELOG](../CHANGELOG.md), the README requirements, the package checksum and remaining acceptance scope. Review and commit the intended source files; this implementation preserves pre-existing uncommitted work, including local editor settings, which should be assessed separately.

After maintainer acceptance, create `v1.2.0`, push the intended commit/tag, and publish a GitHub Release with the ZIP and checksum. Use the 1.2.0 changelog entry as release notes and keep the signing and compatibility limitations. Release preparation does not itself create commits, tags, push changes or publish a Release.

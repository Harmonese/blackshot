#!/bin/zsh
set -eu
probe_root="${0:A:h:h:h}"
probe_build="$(mktemp -d "${TMPDIR:-/tmp}/blackshot-validation.XXXXXX")"
trap 'rm -rf "$probe_build"' EXIT
xcrun clang -fobjc-arc -Wall -Wextra -c "$probe_root/Blackshot/NativeScreenshotBridge.m" -o "$probe_build/bridge.o"
xcrun swiftc -parse-as-library -swift-version 5 -import-objc-header "$probe_root/Blackshot/Blackshot-Bridging-Header.h" \
    "$probe_root/Blackshot/CapturedScreenshot.swift" "$probe_root/Blackshot/NativeCaptureService.swift" \
    "$probe_root/Blackshot/ImageInverter.swift" "$probe_root/Blackshot/RecoveryStore.swift" \
    "$probe_root/Blackshot/ScreenshotShortcut.swift" "$probe_root/Blackshot/LanguageManager.swift" \
    "$probe_root/Blackshot/HotkeyTap.swift" "$probe_root/Blackshot/ShortcutSettings.swift" \
    "$probe_root/Experiments/NativeScreenshotBridge/Checks.swift" "$probe_root/Experiments/NativeScreenshotBridge/Validation.swift" \
    "$probe_build/bridge.o" -o "$probe_build/validate"
"$probe_build/validate" "$@"

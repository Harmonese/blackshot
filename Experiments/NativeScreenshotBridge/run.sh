#!/bin/zsh
set -eu
probe_dir="${0:A:h}"
probe_build="$(mktemp -d "${TMPDIR:-/tmp}/blackshot-native-bridge.XXXXXX")"
trap 'rm -f "$probe_build/native-screenshot-bridge"; rmdir "$probe_build"' EXIT
xcrun clang -fobjc-arc -Wall -Wextra -framework AppKit -framework CoreImage \
    "$probe_dir/main.m" -o "$probe_build/native-screenshot-bridge"
"$probe_build/native-screenshot-bridge" "$@"

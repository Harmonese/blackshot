#!/usr/bin/env python3
"""Package a signed Blackshot Release app as a verified drag-to-install DMG."""

import argparse
import hashlib
from pathlib import Path
import plistlib
import subprocess
import tempfile


def run(*args):
    return subprocess.check_output(args)


def files_in(app):
    return {
        path.relative_to(app): hashlib.sha256(path.read_bytes()).digest()
        for path in app.rglob("*") if path.is_file()
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path, help="Path to the signed Release Blackshot.app")
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parent.parent / "build/releases")
    args = parser.parse_args()
    app = args.app.resolve()
    info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    if info.get("CFBundleIdentifier") != "blackshot.Blackshot":
        parser.error("The input must be a Blackshot application bundle.")
    if run("lipo", "-archs", str(app / "Contents/MacOS/Blackshot")).decode().strip() != "arm64":
        parser.error("This package targets arm64 only.")
    run("codesign", "--verify", "--deep", "--strict", str(app))

    args.output.mkdir(parents=True, exist_ok=True)
    output = args.output.resolve()
    name = f"Blackshot-{info['CFBundleShortVersionString']}-macos-arm64.dmg"
    with tempfile.TemporaryDirectory(prefix=".blackshot-dmg-", dir=output) as folder:
        work = Path(folder)
        contents = work / "contents"
        contents.mkdir()
        run("ditto", str(app), str(contents / "Blackshot.app"))
        (contents / "Applications").symlink_to("/Applications")
        image = work / name
        run("hdiutil", "create", "-volname", "Blackshot", "-srcfolder", str(contents),
            "-fs", "HFS+", "-format", "UDZO", str(image))
        run("hdiutil", "verify", str(image))

        mount = work / "mounted"
        mount.mkdir()
        run("hdiutil", "attach", "-readonly", "-nobrowse", "-mountpoint", str(mount), str(image))
        try:
            mounted_app = mount / "Blackshot.app"
            run("codesign", "--verify", "--deep", "--strict", str(mounted_app))
            if files_in(app) != files_in(mounted_app):
                raise RuntimeError("The mounted application differs from the Release build.")
            if (mount / "Applications").readlink() != Path("/Applications"):
                raise RuntimeError("The Applications shortcut is incorrect.")
        finally:
            run("hdiutil", "detach", str(mount))

        destination = output / name
        image.replace(destination)

    checksum = hashlib.sha256(destination.read_bytes()).hexdigest()
    destination.with_suffix(".dmg.sha256").write_text(f"{checksum}  {name}\n")
    print(f"Verified DMG: {destination}")
    print(f"SHA-256: {checksum}")


if __name__ == "__main__":
    main()

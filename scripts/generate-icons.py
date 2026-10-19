#!/usr/bin/env python3
"""Render the Blackshot SVG into the existing PNG icon assets (requires librsvg)."""

import json
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile


def main():
    root = Path(__file__).resolve().parent.parent
    renderer = shutil.which("rsvg-convert")
    if not renderer:
        raise SystemExit("rsvg-convert is required; install librsvg to regenerate icons.")

    catalog = root / "Blackshot/Assets.xcassets/AppIcon.appiconset"
    images = json.loads((catalog / "Contents.json").read_text())["images"]
    targets = {root / "icon.png": 1024}
    for image in images:
        width, height = map(int, image["size"].split("x"))
        scale = int(image["scale"].removesuffix("x"))
        if width != height:
            raise SystemExit("App icon slots must be square.")
        targets[catalog / image["filename"]] = width * scale

    # Finish all rendering before replacing any checked-in assets.
    with tempfile.TemporaryDirectory(prefix="blackshot-icons-") as folder:
        rendered = {}
        for size in sorted(set(targets.values())):
            output = Path(folder) / f"{size}.png"
            subprocess.run([
                renderer, "--width", str(size), "--height", str(size),
                "--output", str(output), str(root / "icon.svg"),
            ], check=True)
            data = output.read_bytes()
            if data[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack(">II", data[16:24]) != (size, size):
                raise SystemExit(f"Invalid rendered PNG at {size}px.")
            rendered[size] = data
        for path, size in targets.items():
            path.write_bytes(rendered[size])
            print(f"Generated {path.relative_to(root)} ({size}×{size})")


if __name__ == "__main__":
    main()

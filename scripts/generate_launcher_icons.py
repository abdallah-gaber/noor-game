#!/usr/bin/env python3
"""Render the Noor lantern launcher assets with ImageMagick."""

import json
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "android/app/src/main/res"
IOS = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"

# The handle, roof, glass and smile follow NoorLantern's resting expression.
FRAME = """
<circle cx="88" cy="40" r="15" fill="CURRENT"/>
<path d="M46 73 Q51 61 79 46 Q88 41 97 46 Q125 61 130 73Z" fill="CURRENT"/>
<rect x="48" y="68" width="80" height="76" rx="18" fill="CURRENT"/>
<rect x="44" y="135" width="88" height="15" rx="7" fill="CURRENT"/>
"""
FACE = """
<rect x="56" y="75" width="64" height="59" rx="12" fill="#FFD575"/>
<ellipse cx="70" cy="109" rx="7" ry="3.5" fill="#F79A72"/>
<ellipse cx="106" cy="109" rx="7" ry="3.5" fill="#F79A72"/>
<circle cx="73" cy="98" r="3.5" fill="#332A24"/>
<circle cx="103" cy="98" r="3.5" fill="#332A24"/>
<path d="M78 109 Q88 119 98 109 Q88 129 78 109Z" fill="#332A24"/>
"""
COLOR = (
    '<circle cx="88" cy="88" r="65" fill="#FFEDBC"/>'
    '<path d="M133 50l3 7 7 3-7 3-3 7-3-7-7-3 7-3Z" fill="#AC722C"/>'
    + FRAME.replace("CURRENT", "#235349")
    + '<circle cx="88" cy="39" r="7" fill="#FFEDBC"/>' + FACE
)
# Alpha cutouts retain a smiling face when the launcher supplies the color.
MONO = FRAME.replace("CURRENT", "white")
CUTOUTS = """
<circle cx="88" cy="39" r="7" fill="white"/>
<circle cx="73" cy="98" r="4.5" fill="white"/>
<circle cx="103" cy="98" r="4.5" fill="white"/>
<path d="M77 108 Q88 118 99 108 Q88 131 77 108Z" fill="white"/>
"""


def render(path, size, graphic, background="", viewbox="0 0 176 176", opaque=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{size * 4}" height="{size * 4}" viewBox="{viewbox}">{background}{graphic}</svg>'
    subprocess.run(
        ["magick", "-background", "none", "svg:-", "-resize", f"{size}x{size}",
         f"{'PNG24' if opaque else 'PNG32'}:{path}"],
        input=svg.encode(), check=True,
    )


def main():
    tile = '<rect width="176" height="176" rx="34" fill="#235349"/>'
    for density, size in zip(("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"),
                             (48, 72, 96, 144, 192), strict=True):
        render(ANDROID / f"mipmap-{density}/ic_launcher.png", size, COLOR, tile)
        render(ANDROID / f"mipmap-{density}/ic_launcher_round.png", size, COLOR,
               '<circle cx="88" cy="88" r="88" fill="#235349"/>')
        render(ANDROID / f"drawable-{density}/noor_splash.png", size * 6, COLOR,
               viewbox="-44 -44 264 264")
        render(ANDROID / f"drawable-{density}/noor_splash_legacy.png",
               round(size * 128 / 48), COLOR)
    layers = ANDROID / "drawable-nodpi"
    render(layers / "noor_launcher_foreground.png", 432, COLOR, viewbox="-24 -24 224 224")
    with TemporaryDirectory() as directory:
        shape = Path(directory) / "shape.png"
        mask = Path(directory) / "mask.png"
        for path, graphic in ((shape, MONO), (mask, CUTOUTS)):
            render(path, 432, graphic, viewbox="-24 -24 224 224")
        subprocess.run(
            ["magick", str(shape), str(mask), "-compose", "DstOut", "-composite",
             f"PNG32:{layers / 'noor_launcher_monochrome.png'}"], check=True,
        )
    launch = IOS.parent / "LaunchImage.imageset"
    for scale, suffix in enumerate(("", "@2x", "@3x"), 1):
        render(launch / f"LaunchImage{suffix}.png", 144 * scale, COLOR)
    for entry in json.loads((IOS / "Contents.json").read_text())["images"]:
        size = int(float(entry["size"].split("x")[0]) * int(entry["scale"][0]))
        render(IOS / entry["filename"], size, COLOR,
               '<rect width="176" height="176" fill="#235349"/>', opaque=True)


if __name__ == "__main__":
    main()

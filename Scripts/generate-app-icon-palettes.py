#!/usr/bin/env python3
"""Generate Zee's palette app icons, selector previews and Dock images from the Zee glyph.

The default icon (`Zee.icon`) shows the glyph in Zee cyan on white. Each palette
icon shows the same glyph in white on that palette's field color. The macOS
renderer (`ictool`) exports the finished Dock images in light and dark.
"""
import json
import re
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ICON_ROOT = ROOT / "ZeeShared/Resources/ZeeIcon"
PREVIEWS = ROOT / "ZeeShared/Resources/AppIconPreviews.xcassets"
GLYPH = ICON_ROOT / "Zee.icon/Assets/ZeeTemporaryGlyph.svg"
GLYPH_NAME = GLYPH.name

DEFAULT_FIELD = "#FFFFFF"
# Each palette's field color, as its Space fields wear it.
PALETTE_FIELDS = {
    "Dragon": "#7A1E12",
    "Iron": "#2C3A3C",
    "Lion": "#722030",
    "Meadow": "#345738",
    "River": "#22486C",
    "Storm": "#313848",
    "Sun": "#8B3D1B",
    "Vigil": "#272A2E",
    "Winter": "#3E4E5E",
}


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def srgb(color):
    channels = (int(color[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return "srgb:" + ",".join(f"{channel:.5f}" for channel in channels) + ",1.00000"


def lightened(color, amount):
    channels = (int(color[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return "#" + "".join(f"{round((channel + (1 - channel) * amount) * 255):02X}" for channel in channels)


def icon_document(field, dark_glyph=None):
    layer = {"image-name": GLYPH_NAME, "name": GLYPH.stem}
    if dark_glyph:
        # Palette fields are dark, so the system's dark rendition would draw the
        # glyph nearly black on black. Give it a light tint of the palette instead.
        layer["fill-specializations"] = [
            {"value": "automatic"},
            {"appearance": "dark", "value": {"solid": srgb(dark_glyph)}},
        ]
    return {
        "fill": {"solid": srgb(field)},
        "groups": [{
            "name": "Zee",
            "layers": [layer],
            "shadow": {"kind": "neutral", "opacity": 0.2},
            "translucency": {"enabled": False, "value": 0.4},
        }],
        "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
    }


def glyph_svg(color):
    return re.sub(r'fill="#[0-9A-Fa-f]{6}"', f'fill="{color}"', GLYPH.read_text())


def write_palette_icon(name, field):
    destination = ICON_ROOT / ("Zee" + name + ".icon")
    assets = destination / "Assets"
    assets.mkdir(parents=True, exist_ok=True)
    for stale in assets.glob("*.svg"):
        stale.unlink()
    (assets / GLYPH_NAME).write_text(glyph_svg("#FFFFFF"))
    write_json(destination / "icon.json", icon_document(field, lightened(field, 0.6)))


def export_images():
    # Selector previews (60pt at 3x, light and dark) and complete Mac Dock icons
    # at 1x and 2x, all from Apple's renderer. Runtime callers load these
    # directly; Clear and Tinted go through Icon Services.
    developer = Path(subprocess.check_output(["xcode-select", "-p"], text=True).strip())
    exporter = developer.parent / "Applications/Icon Composer.app/Contents/Executables/ictool"
    with tempfile.TemporaryDirectory(prefix="zee-icon-export-") as temporary:
        working = Path(temporary)
        padding_tool = working / "pad-mac-app-icon"
        subprocess.run(["xcrun", "swiftc", str(ROOT / "Scripts/pad-mac-app-icon.swift"),
                        "-o", str(padding_tool)], check=True)
        for source in ICON_ROOT.glob("Zee*.icon"):
            preview = PREVIEWS / (source.stem + "Preview.imageset")
            preview.mkdir(exist_ok=True)
            for stale in preview.glob("*.svg"):
                stale.unlink()
            for filename, rendition in [("icon.png", "Default"), ("icon-dark.png", "Dark")]:
                subprocess.run([str(exporter), str(source), "--export-image", "--output-file", str(preview / filename),
                                "--platform", "iOS", "--rendition", rendition,
                                "--width", "60", "--height", "60", "--scale", "3"],
                               check=True, stdout=subprocess.DEVNULL)
            write_json(preview / "Contents.json", {
                "images": [
                    {"filename": "icon.png", "idiom": "universal", "scale": "3x"},
                    {"appearances": [{"appearance": "luminosity", "value": "dark"}],
                     "filename": "icon-dark.png", "idiom": "universal", "scale": "3x"},
                ],
                "info": {"author": "xcode", "version": 1},
            })
            for appearance, rendition in [("Light", "Default"), ("Dark", "Dark")]:
                target = PREVIEWS / (source.stem + "Dock" + appearance + ".imageset")
                target.mkdir(exist_ok=True)
                images = []
                for scale in (1, 2):
                    filename = "icon.png" if scale == 1 else "icon@2x.png"
                    face = working / "face.png"
                    subprocess.run([str(exporter), str(source), "--export-image", "--output-file", str(face),
                                    "--platform", "macOS", "--rendition", rendition,
                                    "--width", "412", "--height", "412", "--scale", str(scale)],
                                   check=True, stdout=subprocess.DEVNULL)
                    subprocess.run([str(padding_tool), str(face), str(target / filename), str(512 * scale)],
                                   check=True)
                    images.append({"filename": filename, "idiom": "mac", "scale": f"{scale}x"})
                write_json(target / "Contents.json", {"images": images, "info": {"author": "xcode", "version": 1}})


def main():
    PREVIEWS.mkdir(exist_ok=True)
    write_json(PREVIEWS / "Contents.json", {"info": {"author": "xcode", "version": 1}})
    write_json(ICON_ROOT / "Zee.icon/icon.json", icon_document(DEFAULT_FIELD))
    for name, field in PALETTE_FIELDS.items():
        write_palette_icon(name, field)
    export_images()
    print(f"Generated {len(PALETTE_FIELDS)} palette icons and previews.")


if __name__ == "__main__":
    main()

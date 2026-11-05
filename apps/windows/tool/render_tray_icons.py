"""Renders the tray icons from the shared Hub app icon (installer-toolkit/assets/setup-icon.svg).

The tray shows the same mark as the exe: the green D with the download badge. The light-taskbar
icon is that mark as is. The dark-taskbar icon repaints the D's counter (maroon) white so it keeps
its contrast on a dark taskbar; the badge is unchanged.

Usage: python tool/render_tray_icons.py [--resvg D:\tools\resvg\resvg.exe]
Needs Pillow and resvg. Writes assets/tray_icon.ico (light) and assets/tray_icon_dark.ico (dark).
"""
import argparse
import io
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parents[1] / "installer-toolkit/assets/setup-icon.svg"
COUNTER = "#893750"
SIZES = (16, 20, 24, 32, 40, 48, 64)


def render(svg: Path, size: int, resvg: str) -> Image.Image:
    out = svg.with_suffix(f".{size}.png")
    subprocess.run([resvg, "--width", str(size), "--height", str(size), str(svg), str(out)], check=True)
    return Image.open(io.BytesIO(out.read_bytes())).convert("RGBA")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--resvg", default=r"D:\tools\resvg\resvg.exe")
    args = ap.parse_args()
    svg = SOURCE.read_text(encoding="utf-8")
    assert svg.count(f'fill="{COUNTER}"') == 1, "the counter fill moved in setup-icon.svg"
    variants = {"tray_icon.ico": svg, "tray_icon_dark.ico": svg.replace(f'fill="{COUNTER}"', 'fill="#FFFFFF"')}
    with tempfile.TemporaryDirectory(dir=ROOT / "build") as work:
        for name, text in variants.items():
            path = Path(work) / (name + ".svg")
            path.write_text(text, encoding="utf-8")
            frames = [render(path, s, args.resvg) for s in SIZES]
            frames[-1].save(ROOT / "assets" / name, format="ICO", sizes=[(s, s) for s in SIZES], append_images=frames[:-1])
            print(name, [im.size for im in frames])


if __name__ == "__main__":
    main()

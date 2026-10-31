"""Renders the Inno Setup wizard artwork from installer assets.

Generates the per-DPI wizard image set for Inno Setup 5.6.1 from one master
SVG design each for the side panel and the corner glyph, using the brand
identity of dynamotivation.com:

  --main-color #ff4c4a, --main-color-dark #893750,
  accent gradient #3dffe5 -> #38e89f -> #4aff80, Rubik type.

Requires: Pillow, fonttools+brotli (pip), and resvg.exe at D:\\tools\\resvg.
Usage (from the repo root):
    py installer\\tools\\render_assets.py [path\\to\\resvg.exe]
Writes installer/assets/wizard-large-{100..250}.bmp and
installer/assets/wizard-small-{100..250}.bmp (24-bit BMP, Inno 5.6).
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from PIL import Image
from fontTools.ttLib import TTFont

ASSETS = Path(__file__).resolve().parent.parent / "assets"
RUBIK_WEBFONTS = Path(r"D:\source\repos\dynamotivation.github.io\static\fonts\rubik\webfonts")

# Inno 5.6 wizard image areas (pre-6.6 scaling): side panel is 164:314.
LARGE_SIZES = [(164, 314), (202, 386), (240, 459), (290, 556), (315, 604), (366, 700), (416, 797)]
SMALL_SIZES = [(58, 58), (71, 71), (85, 85), (103, 103), (112, 112), (129, 129), (147, 147)]

# The D glyph paths from assets/setup-logo.svg (96x96 box, logo group scaled .875 inside the file).
D_BODY = "m38.755521 28.548018c-2.407689.0-3.611479 1.338813-3.611479 4.015792v31.321617c0 2.676978 1.20379 4.015793 3.611479 4.015793v-.002h5.635c5.489582.0 9.677583-1.712143 12.56693-5.138886 2.889347-3.533714 4.285998-8.407106 4.189628-14.617797C61.050829 41.717756 59.559598 36.846319 56.67033 33.526741c-2.889346-3.319382-7.030939-4.978723-12.424346-4.978723z"
D_OUTLINE = (
    "M39.777048.01362565c-4.569288.03355613-9.144388-.09558083-13.709556.123052C17.857638.70274705 "
    "10.482807 7.009944 8.4495708 14.953701c-1.4195807 5.069414-.7790142 10.378144-.918007 15.567055."
    "015287 15.260154-.057889 30.522251.089848 45.781204.4297339 6.834635 4.0273147 13.657344 10.0726857 "
    "17.108135 4.485535 2.739084 9.906824 3.259831 15.051408 3.02161 6.471659-.08575 12.964943.243664 "
    "19.418778-.349624C62.494502 94.756378 72.147732 89.072956 78.389985 80.745505 85.298053 71.850616 "
    "88.661607 60.526265 88.734166 49.335993 88.990779 38.878107 86.456441 28.237704 80.782663 19.385527 "
    "74.468852 9.4965906 63.823247 2.4654463 52.207253.69920109 48.104994-990178e-9 43.927219-.03532222 "
    "39.777048.01362565zM31.098952 15.69592h13.147032c6.356523.0 11.748314 1.445005 16.178409 4.336118 "
    "4.430291 2.784144 7.802381 6.639248 10.113702 11.564935 2.407692 4.818718 3.611479 10.334921 "
    "3.611479 16.545611.0 6.424827-1.203787 12.098459-3.611479 17.024147-2.407691 4.925688-5.68325 "
    "8.780792-9.824628 11.564935-4.141181 2.676981-8.763274 4.015792-13.867765 4.015792l-14.879526.002c"
    "-2.985521.0-5.392901-.910181-7.222958-2.730582-1.733588-1.927468-2.60167-4.443757-2.60167-7.549143V25."
    "655319c0-3.105443.819856-5.515545 2.457133-7.228817 1.637255-1.8204 3.803607-2.730582 6.500271-2."
    "730582z"
)
# ([Setup] logo mark from the site) download-arrow badge circle, 96x96 box.
BADGE = '<circle cx="72" cy="72" r="21" fill="url(#badge)" stroke="#FFFFFF" stroke-width="3"/>'
ARROW = (
    '<g fill="none" stroke="#FFFFFF" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M72 62v14"/><path d="M66 70.5 72 76.5 78 70.5"/><path d="M64.5 82h15"/></g>'
)

GRADIENT_DEFS = (
    '<linearGradient id="stem" x1="0" y1="0" x2="1" y2="1">'
    '<stop offset="0" stop-color="#3dffe5"/><stop offset="1" stop-color="#4aff80"/></linearGradient>'
    '<linearGradient id="badge" x1="0" y1="0" x2="1" y2="1">'
    '<stop offset="0" stop-color="#CC3C3B"/><stop offset="1" stop-color="#893750"/></linearGradient>'
)

# The full rounded Dynamotivation product logo (no installer badge).
def product_mark() -> str:
    return (
        '<g transform="scale(.875)">'
        f'<path d="{D_BODY}" fill="#893750"/><path d="{D_OUTLINE}" fill="url(#stem)"/>'
        "</g>"
    )

# The installer mark: product D with the burgundy download badge (no white ring).
def installer_mark() -> str:
    return (
        product_mark()
        + '<circle cx="72" cy="72" r="21" fill="url(#badge)"/>'
        + '<g fill="none" stroke="#FFFFFF" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round">'
          '<path d="M72 62v14"/><path d="M66 70.5 72 76.5 78 70.5"/><path d="M64.5 82h15"/></g>'
    )


def large_svg() -> str:
    """164x314 side panel: official full roundel above the installer mark, burgundy line, Rubik wordmark."""
    full_logo = (ASSETS / "full-logo.svg").read_text(encoding="utf-8")
    # strip the outer <svg> wrapper, keep the <defs> and drawing group, and
    # rename the borrowed gradient id so it cannot collide with ours
    inner = full_logo.split("<svg", 1)[1].split(">", 1)[1].rsplit("</svg>", 1)[0]
    inner = inner.replace('id="a"', 'id="brandstem"').replace('url(#a)', 'url(#brandstem)')
    mark = 78  # upper and lower marks render at the same size
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="164" height="314" viewBox="0 0 164 314">
  <defs>{GRADIENT_DEFS}</defs>
  <rect width="164" height="314" fill="#ffffff"/>
  <g transform="translate(43,32) scale({78 / 315.23:.6f})">{inner}</g>
  <g transform="translate(43,116) scale({mark / 96:.6f})">{installer_mark()}</g>
  <rect x="47" y="226" width="70" height="5" rx="2.5" fill="url(#badge)"/>
  <text x="82" y="257" font-family="Rubik" font-weight="700" font-size="13.5" fill="#2c2c2c" text-anchor="middle">Dynamotivation</text>
  <text x="82" y="277" font-family="Rubik" font-weight="400" font-size="10" fill="#893750" text-anchor="middle">Software Hub</text>
</svg>"""


def small_svg() -> str:
    """Square corner glyph on white, matching the wizard's white surface."""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="147" height="147" viewBox="0 0 147 147">
  <defs>{GRADIENT_DEFS}</defs>
  <rect width="147" height="147" fill="#ffffff"/>
  <g transform="translate(11,11) scale(1.30)">{installer_mark()}</g>
</svg>"""


def setup_icon_svg() -> str:
    """96x96 installer icon: product D with the badge cut out of it."""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
  <defs>{GRADIENT_DEFS}
    <mask id="bitethrough">
      <rect width="96" height="96" fill="#ffffff"/>
      <!-- flush with the badge circle (r 21 + 0.8 anti-aliasing headroom) -->
      <circle cx="72" cy="72" r="21.8" fill="#000000"/>
    </mask>
  </defs>
  <g mask="url(#bitethrough)">
    <g transform="scale(.875)">
      <path d="{D_BODY}" fill="#893750"/>
      <path d="{D_OUTLINE}" fill="url(#stem)"/>
    </g>
  </g>
  <circle cx="72" cy="72" r="21" fill="url(#badge)"/>
  <g fill="none" stroke="#FFFFFF" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M72 62v14"/><path d="M66 70.5 72 76.5 78 70.5"/><path d="M64.5 82h15"/>
  </g>
</svg>"""



def convert_fonts(temp: Path) -> str:
    """Provide a font dir with real Rubik instances for resvg."""
    fonts = Path(r"D:\tools\resvg\fonts")  # Rubik-Regular.ttf / Rubik-Bold.ttf instanced from Google's variable font
    if (fonts / "Rubik-Bold.ttf").exists():
        return str(fonts)
    for source, target in (
        (RUBIK_WEBFONTS / "rubik-v28-latin-700.woff2", temp / "Rubik-Bold.ttf"),
        (RUBIK_WEBFONTS / "rubik-v28-latin-regular.woff2", temp / "Rubik-Regular.ttf"),
    ):
        font = TTFont(source)
        font.flavor = None  # save as plain sfnt, not the woff2 it was loaded from
        font.save(target)
    return str(temp)


def render(svg_path: Path, out_png: Path, resvg: str, font_dir: str, size: tuple[int, int]) -> None:
    subprocess.run(
        [resvg, "--width", str(size[0]), "--height", str(size[1]), "--use-fonts-dir", font_dir, str(svg_path), str(out_png)],
        check=True,
    )


def to_bmp(png_path: Path, bmp_path: Path, size: tuple[int, int], master: tuple[int, int]) -> None:
    im = Image.open(png_path).convert("RGB")
    if size != master:
        im = im.resize(size, Image.LANCZOS)
    im.save(bmp_path)


def main() -> None:
    resvg = sys.argv[1] if len(sys.argv) > 1 else r"D:\tools\resvg\resvg.exe"
    tmp = ASSETS / ".render-tmp"
    tmp.mkdir(exist_ok=True)
    font_dir = convert_fonts(tmp)

    # Installer icon (D with the badge cut out), as a multi-size .ico.
    svg_file = tmp / "setup-icon.svg"
    svg_file.write_text(setup_icon_svg(), encoding="utf-8")
    icon_png = tmp / "setup-icon.png"
    subprocess.run([resvg, "--width", "256", "--height", "256", "--use-fonts-dir", font_dir, str(svg_file), str(icon_png)], check=True)
    icon = Image.open(icon_png)
    icon.save(ASSETS / "setup.ico", sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print("setup.ico")

    for name, svg_text, sizes in (("wizard-large", large_svg(), LARGE_SIZES), ("wizard-small", small_svg(), SMALL_SIZES)):
        svg_file = tmp / f"{name}.svg"
        svg_file.write_text(svg_text, encoding="utf-8")
        master = (sizes[-1][0] * 2, sizes[-1][1] * 2)  # render 2x of the largest, then downscale
        render(svg_file, tmp / f"{name}-master.png", resvg, font_dir, master)
        dpi_map = (
            {58: 100, 71: 125, 85: 150, 103: 175, 112: 200, 129: 225, 147: 250}
            if name == "wizard-small"
            else {164: 100, 202: 125, 240: 150, 290: 175, 315: 200, 366: 225, 416: 250}
        )
        for size in sizes:
            to_bmp(tmp / f"{name}-master.png", ASSETS / f"{name}-{dpi_map[size[0]]}.bmp", size, master)
            print(f"{name}-{dpi_map[size[0]]}.bmp {size}")

    print("done")


if __name__ == "__main__":
    main()

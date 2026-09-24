#!/usr/bin/env python3
"""Derive the bar's artwork from the sheet's native icons, tinted to the palette.

The sheet's reds sit near 97% saturation and its bone is warm; the theme is a cold slate with
a darker blood. Left as drawn, the art clashes with everything around it. So:

  - reds go onto the palette's blood hue through gen-assets' retint;
  - every other near-neutral pixel takes the cold bone hue and keeps its own lightness, which
    is what preserves the ink shading and the grain.

Source: assets/native/  (scripts/extract-sheet.py)   Output: bar/modules/ito-art/, same layout.

    gen-art.py                write into bar/modules/ito-art
    gen-art.py --out DIR      write somewhere else (the lab uses /tmp)
"""
import argparse
import math
import colorsys
import importlib.util
import sys
import tomllib
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
BONE_HUE, BONE_SAT = 210 / 360, 0.09     # #c7ccd1 is H 210, S ~10%


def load_gen_assets():
    spec = importlib.util.spec_from_file_location("gen_assets", REPO / "scripts" / "gen-assets.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def tint(img: Image.Image, ga, hue: float, cfg: dict) -> Image.Image:
    img, _ = ga.retint(img.convert("RGBA"), hue, cfg["red_saturation"], cfg)
    px = np.asarray(img).copy()
    r, g, b = (px[..., i].astype(float) / 255 for i in range(3))
    mx, mn = np.maximum(np.maximum(r, g), b), np.minimum(np.minimum(r, g), b)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    red = (r > g * 1.25) & (r > b * 1.25) & (sat > 0.35)
    ys, xs = np.where((px[..., 3] > 8) & ~red)
    for y, x in zip(ys, xs):
        lightness = colorsys.rgb_to_hls(r[y, x], g[y, x], b[y, x])[1]
        px[y, x, :3] = [round(c * 255) for c in colorsys.hls_to_rgb(BONE_HUE, lightness, BONE_SAT)]
    return Image.fromarray(px, "RGBA")


def sharpen(img: Image.Image, radius: float, percent: int) -> Image.Image:
    """Unsharp mask on premultiplied colour and on alpha.

    The bar shows this art at 30-40% of its native size, and the renderer's resampling softens
    it. A mild sharpen at the source gives that resampling crisper edges to work from. Done on
    premultiplied colour so the transparent surround cannot bleed a dark fringe into the edge.
    """
    px = np.asarray(img.convert("RGBA")).astype(np.float32)
    alpha = px[..., 3] / 255.0
    premult = np.clip(px[..., :3] * alpha[..., None], 0, 255).astype(np.uint8)
    mask = ImageFilter.UnsharpMask(radius=radius, percent=percent, threshold=1)
    rgb = np.asarray(Image.fromarray(premult).filter(mask)).astype(np.float32)
    a2 = np.asarray(Image.fromarray((alpha * 255).astype(np.uint8)).filter(mask)).astype(np.float32) / 255.0
    out_rgb = np.clip(rgb / np.maximum(a2, 1e-3)[..., None], 0, 255)
    return Image.fromarray(np.dstack([out_rgb, a2 * 255]).astype(np.uint8), "RGBA")



RED_DEEP, RED_LIVE = (58, 8, 16), (196, 22, 42)     # the duotone for numerals painted red
INK = (11, 13, 14)


def duotone(img: Image.Image, dark, bright, gamma: float = 0.85) -> Image.Image:
    """Recolour by luminance between two colours, keeping alpha. Shading and grain survive."""
    px = np.asarray(img.convert("RGBA")).astype(np.float32)
    lum = np.clip(px[..., :3].max(axis=2) / 255.0, 0, 1) ** gamma
    out = np.empty_like(px)
    for i in range(3):
        out[..., i] = dark[i] + (bright[i] - dark[i]) * lum
    out[..., 3] = px[..., 3]
    return Image.fromarray(out.astype(np.uint8), "RGBA")


def ring_of(img: Image.Image):
    """Centre and radius of a ring drawing, from the box of its ink."""
    box = img.getbbox()
    return ((box[0] + box[2]) / 2, (box[1] + box[3]) / 2, max(box[2] - box[0], box[3] - box[1]) / 2)


def radial_mask(size, centre, radius, inner: float, feather: float = 0.10, outside: bool = False):
    """A soft-edged disc (or, with `outside`, its complement) of `inner` x the ring's radius."""
    mask = Image.new("L", size, 0)
    px = mask.load()
    cx, cy = centre
    for y in range(size[1]):
        for x in range(size[0]):
            d = math.hypot(x - cx, y - cy) / radius
            inside = 1.0 - min(1.0, max(0.0, (d - (inner - feather / 2)) / feather))
            px[x, y] = int(255 * ((1.0 - inside) if outside else inside))
    return mask


def active_numeral(digit: Image.Image, red2: Image.Image, split: float = 0.60) -> Image.Image:
    """The sheet's own red ring, with another number written inside it.

    The sheet draws the active workspace as a thick red ring around a bone digit, and that ring has
    a volume no recolouring reproduces (a first attempt that tinted the outside of the bone ring
    came out thin and dim). So every active numeral reuses the real red ring - the 2's - with its
    digit cleared and the wanted digit set in its place, scaled to the same ring.
    """
    c2x, c2y, r2 = ring_of(red2)
    cx, cy, r = ring_of(digit)
    scale = r2 / r
    resized = digit.resize((max(1, round(digit.width * scale)), max(1, round(digit.height * scale))), Image.LANCZOS)
    placed = Image.new("RGBA", red2.size, (0, 0, 0, 0))
    placed.paste(resized, (round(c2x - cx * scale), round(c2y - cy * scale)))
    inner = radial_mask(red2.size, (c2x, c2y), r2, split)
    ring = red2.copy()
    ring.putalpha(Image.composite(Image.new("L", red2.size, 0), red2.getchannel("A"), inner))
    digit_only = placed.copy()
    digit_only.putalpha(Image.composite(placed.getchannel("A"), Image.new("L", red2.size, 0), inner))
    return Image.alpha_composite(ring, digit_only)


def numerals(out: Path, ga, hue: float, cfg: dict) -> int:
    """ws-1..10 in bone and in red. The sheet has 1-5 (and its 2 is already red); 6-10 come from
    the synthesised set. Red is a duotone so every numeral reads as the same blood."""
    native = REPO / "assets" / "native" / "workspace-labels"
    synth = REPO / "assets" / "icons-precision" / "64" / "workspace-labels"
    dst = out / "workspace-labels"
    dst.mkdir(parents=True, exist_ok=True)
    count = 0
    red2 = tint(Image.open(native / "ws-2.png").convert("RGBA"), ga, hue, cfg)
    for n in range(1, 11):
        src = native / f"ws-{n}.png" if n <= 5 else synth / f"ws-{n}.png"
        if not src.is_file():
            continue
        base = Image.open(src).convert("RGBA")
        if n == 2:                                    # the sheet's 2 is the red one
            red = tint(base, ga, hue, cfg)
            bone = duotone(base, (24, 28, 32), (199, 204, 209))
        else:
            bone = tint(base, ga, hue, cfg)
            red = active_numeral(bone, red2)
        bone.save(dst / f"ws-{n}.png")
        red.save(dst / f"ws-{n}-red.png")
        count += 2
    return count


def bold_vein(out: Path) -> None:
    """The sheet's Tomie mark is 17x72: at bar size it thins to nothing. Scale it up, thicken it and
    push it to a live red, so it can flank the seal and still be seen."""
    src = Image.open(REPO / "assets" / "native" / "tomie" / "tomie-mark.png").convert("RGBA")
    big = src.resize((src.width * 4, src.height * 4), Image.LANCZOS)
    alpha = big.getchannel("A").filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(1.2))
    alpha = alpha.point(lambda v: min(255, int(v * 1.5)))
    vein = duotone(big, (120, 10, 24), (214, 30, 50), 0.7)
    vein.putalpha(alpha)
    (out / "tomie").mkdir(parents=True, exist_ok=True)
    vein.save(out / "tomie" / "tomie-vein.png")


def surface(out: Path) -> None:
    """The bar plate, cut from the user's mock-up (dev/reference/bar-target.png): near-black with blood
    veins in patches. The border is left out (the surface draws its own).

    Mirroring the strip to tile it draws butterfly shapes at every seam, so instead the strip is joined
    to a copy of itself turned 180 degrees with a crossfade, and the wrap-around is crossfaded too:
    the texture repeats with no visible seam and no symmetry.
    """
    ref = REPO / "dev" / "reference" / "bar-target.png"
    if not ref.is_file():
        print("surface: no mock-up at dev/reference/bar-target.png, skipped")
        return
    img = Image.open(ref).convert("RGB")
    strip = img.crop((27, 290, 27 + 1948, 290 + 82)).crop((8, 6, 1948 - 8, 82 - 6))     # inside the border
    # Scale up so the veins keep their weight at bar size, then keep the middle band that shows.
    scale = 68 / strip.height
    strip = strip.resize((round(strip.width * scale), 68), Image.LANCZOS).crop((0, 12, round(strip.width * scale), 56))
    a_px = np.asarray(strip).astype(np.float32)
    b_px = a_px[::-1, ::-1]                                    # 180 degrees: a different pattern
    blend = 160
    ramp = np.linspace(0, 1, blend, dtype=np.float32)[None, :, None]
    joint = a_px[:, -blend:] * (1 - ramp) + b_px[:, :blend] * ramp
    joined = np.concatenate([a_px[:, :-blend], joint, b_px[:, blend:]], axis=1)
    period = joined.shape[1] - blend
    wrap = joined[:, period:] * (1 - ramp) + joined[:, :blend] * ramp     # tail fades into head
    tile = np.concatenate([wrap, joined[:, blend:period]], axis=1)
    tile = np.clip(tile * np.array([1.12, 1.0, 1.0], dtype=np.float32), 0, 255)          # a touch more blood
    (out / "surface").mkdir(parents=True, exist_ok=True)
    Image.fromarray(tile.astype(np.uint8)).save(out / "surface" / "veins.png")
    print(f"surface tile {tile.shape[1]}x{tile.shape[0]}")


# Folders whose art sits in a bar slot. Everything in them is squared on its own ink, so one
# `size` in QML means the same optical weight for every icon - the eye, the drive and the dot.
SLOT_DIRS = {
    "audio", "battery", "bluetooth", "brightness", "calendar", "devices", "media", "network",
    "notifications", "quickshell", "status-eyes", "system", "workspace-indicators",
    "workspace-labels", "workspaces",
}


def square(img: Image.Image, fill: float = 0.94) -> Image.Image:
    """Centre the art's own ink on a square canvas.

    The sheet crops arrive with whatever padding the extraction left, so a wide icon and a tall one
    render at different weights under PreserveAspectFit, and an icon whose ink sits off-centre in
    its box looks off-centre in the bar. Cropping to the ink and re-padding fixes both at once.
    """
    box = img.getbbox()
    if not box:
        return img
    ink = img.crop(box)
    side = max(ink.width, ink.height)
    canvas = int(round(side / fill))
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    out.paste(ink, ((canvas - ink.width) // 2, (canvas - ink.height) // 2))
    return out


# Art that comes as a SET of states (a workspace that is empty, occupied, active, urgent; an eye that
# opens as memory fills) is normalised together, not one by one: every image keeps its size relative to
# the biggest in its set and is centred on the middle of its ink. Squaring each image on its own would
# scale a small empty ring up to the size of the bleeding one, and a row of workspaces would come out
# with every mark a different size and none of them on the same line.
SET_DIRS = ("workspaces", "workspace-labels", "workspace-indicators", "status-eyes")


def normalize_sets(out: Path, fill: float = 0.94) -> None:
    for name in SET_DIRS:
        folder = out / name
        files = sorted(folder.glob("*.png"))
        if not files:
            continue
        images = [(f, Image.open(f).convert("RGBA")) for f in files]
        boxes = [(im.getbbox() or (0, 0, im.width, im.height)) for _, im in images]
        # The workspace marks are one mark in four states, so three of them are drawn at one size and only
        # the urgent one, with its spines, may stand a little proud.
        proud = {"indicator-urgent": 1.22}
        base = max(b[2] - b[0] for (f, _), b in zip(images, boxes) if f.stem == "indicator-inactive") \
            if name == "workspace-indicators" else None
        side = max(max(b[2] - b[0], b[3] - b[1]) for b in boxes)
        if base:
            side = int(round(base * 1.22))
        canvas = int(round(side / fill))
        for (f, im), box in zip(images, boxes):
            ink = im.crop(box)
            if base:
                want = int(round(base * proud.get(f.stem, 1.0)))
                k = want / max(ink.width, ink.height)
                ink = ink.resize((max(1, round(ink.width * k)), max(1, round(ink.height * k))), Image.LANCZOS)
            sheet = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
            sheet.paste(ink, ((canvas - ink.width) // 2, (canvas - ink.height) // 2))
            sheet.save(f)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=REPO / "bar" / "modules" / "ito-art")
    ap.add_argument("--sharpen", type=int, default=60, metavar="PERCENT",
                    help="unsharp mask strength (default 60); 0 leaves the art untouched")
    args = ap.parse_args()

    ga = load_gen_assets()
    pal = tomllib.loads((REPO / "themes/ito-verse/palette.toml").read_text())
    hue = pal["assets"].get("red_hue", 0) / 360
    native = REPO / "assets" / "native"
    count = 0
    for src in sorted(native.rglob("*.png")):
        dst = args.out / src.relative_to(native)
        dst.parent.mkdir(parents=True, exist_ok=True)
        raw = Image.open(src).convert("RGBA")
        if src.name == "eye-outline.png":
            # the extraction caught the sheet's vertical rule beside this eye; it drags the eye off-centre
            cut = int(raw.width * 0.86)
            raw.paste((0, 0, 0, 0), (cut, 0, raw.width, raw.height))
        img = tint(raw, ga, hue, pal["assets"])
        if args.sharpen:
            img = sharpen(img, 0.8, args.sharpen)
        if src.parent.name in SLOT_DIRS and src.parent.name not in SET_DIRS:
            img = square(img)
        img.save(dst)
        count += 1
    count += numerals(args.out, ga, hue, pal["assets"])
    normalize_sets(args.out)
    bold_vein(args.out)
    surface(args.out)
    print(f"tinted {count} icons -> {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

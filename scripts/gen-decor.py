#!/usr/bin/env python3
"""The decorations that stand on both sides of the seal, engraved in Junji Ito's manner: heavy ink that swells and
thins, fine echo strokes, blood where something is cut. Each is drawn once (the left one) and mirrored by the
widget. Output is a tight vertical strip, not a square, because it is a thin thing.

    veins     the bloodlines of the original design (tomie/tomie-vein.png, not drawn here)
    thorns    a barbed stem, thorns alternating, blood at the tips
    curls     two small spirals on one stem: the Uzumaki curl
    hair      long strands of black hair, one caught in a curl
    drips     blood running down in three trails that end in drops
    eyes      three eyes stacked, watching, each smaller than the last
    cracks    a crack through the plate that branches, blood in it
    stitches  a seam sewn shut with crossing stitches
    holes     the Amigara Fault: person-shaped holes cut into a pale slab, one of them bleeding
    teeth     a jaw of fangs on a slim spine, red at the root
    chain     a heavy rusted chain, a link torn open at the bottom
    static    the pocket radio's interference as fat bars, blood tears across it
    fog       Silent Hill's fog as manga smoke curls, a dim red glow buried in it

    Drawn for the size they are SHOWN at, which is about 18x34 pixels on the bar: a decoration is a handful of
    bold shapes (strokes of 25+ units, features 60+ units across, aspect about 0.4 to 0.6), never fine detail.
    Check them with a downscale to that size, not a big preview -- a strip 90 units wide is a scratch.

    gen-decor.py     writes bar/modules/ito-art/decor/<name>.png
"""

from __future__ import annotations

import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import eyeart  # noqa: E402
from engrave import BLOOD, BONE, DIM, INK, S, blood, canvas, ellipse, fade, gp, hatch_poly, pen, solid  # noqa: E402

OUT = Path(__file__).resolve().parent.parent / "bar" / "modules" / "ito-art" / "decor"
CX = 320
RUST = (176, 98, 46)
SLAB = (30, 33, 37)
SHEET = Path(__file__).resolve().parent.parent / "bar" / "modules" / "ito-art" / "status-eyes"


def stem(img, x0=CX, y0=40, y1=600, amp=14, waves=3.0, w=(10, 20), color=BONE):
    pts = gp.wave(x0, y0, x0, y1, amp, waves)
    gp.ink(img, pts, w[0], w[1], color, wobble=1.2, pressure=True)
    return pts


def thorns():
    img = canvas()
    pts = stem(img, amp=22, waves=3.5, w=(12, 24))
    rng = random.Random(4)
    for i in range(3, len(pts) - 3, 4):
        x, y = pts[i]
        side = 1 if (i // 4) % 2 == 0 else -1
        ln = rng.uniform(56, 88)
        base = 14
        tip = (x + side * ln, y - rng.uniform(16, 34))
        poly = [(x, y - base), tip, (x, y + base)]
        solid(img, poly, BONE)
        gp.ink(img, [(x, y - base), tip, (x, y + base)], 3, 5, DIM, wobble=0.6, pressure=False)
        ex, ey = tip
        gp.ImageDraw.Draw(img).ellipse((ex - 7, ey - 7, ex + 7, ey + 7), fill=BLOOD + (255,))
    return img


def curls():
    img = canvas()
    stem(img, amp=10, waves=1.6, w=(9, 16))
    for cy, r, turns, side in ((170, 110, 2.6, 1), (430, 130, 2.9, -1)):
        cx = CX + side * 4
        gp.ink(img, gp.spiral(cx, cy, r, turns, n=220, start=0.05), 8, 24, BONE, wobble=1.3, pressure=True)
        gp.ink(img, gp.spiral(cx, cy, r * 0.62, turns * 0.7, n=140, start=0.2), 3, 8, BLOOD, wobble=1.0, pressure=True)
    return img


def hair():
    img = canvas()
    rng = random.Random(9)
    for k in range(6):
        x0 = CX + (k - 2.5) * 30
        x1 = CX + (k - 2.5) * 30 + rng.uniform(-60, 60)
        pts = gp.wave(x0, 30, x1, 610, rng.uniform(16, 34), rng.uniform(1.4, 2.4), phase=k)
        gp.ink(img, pts, 4, rng.uniform(13, 22), BONE if k % 3 else DIM, wobble=1.0, pressure=True)
    # one strand curls up on itself near the end
    gp.ink(img, gp.spiral(CX + 34, 520, 46, 2.2, n=120, start=0.1), 3, 9, BONE, wobble=0.8, pressure=True)
    return img


def drips():
    img = canvas()
    cap = gp.wave(CX - 92, 60, CX + 92, 60, 10, 1.4)
    gp.ink(img, cap, 22, 30, BONE, wobble=1.2, pressure=False)
    for x, ln, w in ((CX - 60, 360, 20), (CX + 2, 500, 26), (CX + 58, 270, 18)):
        trail = [(x, 66), (x + 3, 66 + ln * 0.3), (x - 3, 66 + ln * 0.62), (x + 1, 66 + ln)]
        gp.ink(img, trail, w * 0.6, w, BLOOD, wobble=1.0, pressure=False)
        gp.ink(img, [(x - w * 0.16, 74), (x - w * 0.12, 70 + ln * 0.5)], 3, 5, (255, 130, 140), wobble=0.5, pressure=False)
        yb = 66 + ln
        solid(img, ellipse(x + 1, yb + 6, w * 0.78, w * 1.0), BLOOD)
        gp.ImageDraw.Draw(img).ellipse((x - 5, yb - 4, x + 1, yb + 2), fill=(255, 130, 140, 200))
    return img


def eye_at(img, cx, cy, w, h):
    """The record indicator's own eyeball, cut down to decoration size: a hatched sclera, blood-rimmed
    lids, and an iris in spokes rather than a flat disc -- what made that one read as an eye and not a
    button is the texture, so this borrows it rather than re-inventing a flatter one."""
    top = gp.arc(cx, cy + h * 0.6, w, h * 1.7, math.radians(208), math.radians(332), 40)
    bot = gp.arc(cx, cy - h * 0.6, w, h * 1.7, math.radians(28), math.radians(152), 40)
    solid(img, top + bot, (16, 18, 21))
    hatch_poly(img, top + bot, 20, 11, 2, 0.5, region=fade(cx, cy - h * 0.5, w * 1.6, 255, 0))
    pen(img, top, max(9, h * 0.34), BLOOD, echo=False)
    pen(img, bot, max(8, h * 0.28), BLOOD, echo=False)
    iris = ellipse(cx, cy, h * 0.7, h * 0.7)
    blood(img, iris, None, hatchy=False)
    for a in range(0, 360, 20):
        r = math.radians(a)
        r0, r1 = h * 0.24, h * 0.66
        gp.ink(img, [(cx + math.cos(r) * r0, cy + math.sin(r) * r0), (cx + math.cos(r) * r1, cy + math.sin(r) * r1)],
               2, 3.5, (120, 10, 24), wobble=0.4, pressure=False)
    pen(img, iris, max(6, h * 0.18), BONE, closed=True, echo=False)
    gp.ImageDraw.Draw(img).ellipse((cx - h * 0.26, cy - h * 0.26, cx + h * 0.26, cy + h * 0.26), fill=INK + (255,))
    gp.ImageDraw.Draw(img).ellipse((cx - h * 0.3, cy - h * 0.34, cx - h * 0.12, cy - h * 0.16), fill=BONE + (255,))


def _panel(name, width):
    return Image.open(SHEET.parent / "eyefx" / f"{name}.png").convert("RGBA").resize(
        (width, round(Image.open(SHEET.parent / "eyefx" / f"{name}.png").height * width / Image.open(SHEET.parent / "eyefx" / f"{name}.png").width)), Image.LANCZOS)


def eyes():
    """Three watching eyes with spiral pupils, stacked, the middle one bloodshot, thin blood lines between."""
    img = canvas()
    ys = (130, 320, 510)
    for (name, w), cy in zip((("eyes", 600), ("eyes-red", 540), ("eyes", 480)), ys):
        e = _panel(name, w)
        img.alpha_composite(e, (int(CX - e.width / 2), int(cy - e.height / 2)))
    for y0, y1 in ((ys[0] + 62, ys[1] - 58), (ys[1] + 58, ys[2] - 52)):
        gp.ink(img, [(CX, y0), (CX + 3, (y0 + y1) / 2), (CX, y1)], 3, 6, BLOOD, wobble=0.5, pressure=False)
    return img


def cracks():
    img = canvas()
    main = [(CX + 34, 30), (CX - 28, 140), (CX + 38, 235), (CX - 34, 345), (CX + 28, 450), (CX - 20, 530), (CX + 12, 610)]
    gp.ink(img, main, 8, 24, BLOOD, wobble=1.6, pressure=True)
    gp.ink(img, [(x + 5, y) for x, y in main], 4, 8, BONE, wobble=1.2, pressure=True)
    for i, (dx, dy, ln) in enumerate(((-1, 1, 150), (1, 1, 135), (-1, 1, 120), (1, 1, 145))):
        x, y = main[1 + i * 1 + (1 if i > 1 else 0)]
        branch = [(x, y), (x + dx * ln * 0.5, y + 38), (x + dx * ln, y + 32 + ln * 0.2)]
        gp.ink(img, branch, 5, 14, BONE, wobble=1.4, pressure=True)
        gp.ink(img, [(x + dx * ln * 0.5, y + 38), (x + dx * ln * 0.7, y + 92)], 4, 9, BONE, wobble=1.0, pressure=True)
    return img


def stitches():
    """A seam sewn shut in a hurry: a dark gash with a thread of blood in it, crossing stitches of uneven
    tension pulled across, blood beading at every puncture, two that have given way."""
    img = canvas()
    gash = gp.wave(CX, 40, CX, 606, 8, 1.4)
    gp.ink(img, gash, 14, 22, INK, wobble=1.2, pressure=True)
    gp.ink(img, gash, 5, 9, BLOOD, wobble=1.0, pressure=True)
    rng = random.Random(41)
    y, k = 88, 0
    while y < 580:
        spread = 68 * rng.uniform(0.78, 1.2)
        gp.ink(img, [(CX - spread, y - 24), (CX + spread, y + 24)], 9, 15, BONE, wobble=1.1, pressure=True)
        gp.ink(img, [(CX + spread, y - 24), (CX - spread, y + 24)], 9, 15, BONE, wobble=1.1, pressure=True)
        for px in (CX - spread, CX + spread):
            gp.ImageDraw.Draw(img).ellipse((px - 7, y - 7, px + 7, y + 7), fill=BLOOD + (240,))
        if k in (1, 4):
            sx = CX + rng.uniform(-10, 10)
            solid(img, ellipse(sx, y + 46, 10, 15), BLOOD)
            gp.ink(img, [(CX, y + 24), (sx, y + 64)], 5, 10, BLOOD, wobble=0.6, pressure=False)
        y += rng.uniform(78, 92)
        k += 1
    return img


def veins():
    """A bloodline: one swollen vein down the middle with twigs branching off it, thinning to nothing, and a pale
    highlight along it so it reads as wet ink and not as a smudge."""
    img = canvas()
    rng = random.Random(12)
    main = gp.wave(CX, 30, CX, 610, 26, 2.2)
    gp.ink(img, main, 8, 30, BLOOD, wobble=1.0, pressure=True)
    gp.ink(img, [(x - 5, y) for x, y in main[6:-6]], 2, 5, (255, 120, 132), wobble=0.8, pressure=True)
    for i in range(6, len(main) - 6, 7):
        x, y = main[i]
        side = 1 if (i // 7) % 2 == 0 else -1
        ln = rng.uniform(70, 130)
        pts = [(x, y), (x + side * ln * 0.45, y - rng.uniform(10, 34)), (x + side * ln, y - rng.uniform(34, 76))]
        gp.ink(img, pts, 2, 11, BLOOD, wobble=1.2, pressure=True)
        ex, ey = pts[-1]
        sub = [(pts[1][0], pts[1][1]), (pts[1][0] + side * ln * 0.3, pts[1][1] + 34)]
        gp.ink(img, sub, 2, 7, BLOOD, wobble=1.0, pressure=True)
        gp.ImageDraw.Draw(img).ellipse((ex - 5, ey - 5, ex + 5, ey + 5), fill=BLOOD + (255,))
    return img




def human_hole(img, cx, cy, s):
    """A person-shaped hole, the way the Amigara Fault's are: head, shoulders, one leg to a side each. Each
    one fits somebody exactly, so it is a figure, not a round pit. Black inside, a thin bone edge."""
    head = ellipse(cx, cy - 66 * s, 21 * s, 23 * s)
    body = [(cx - 32 * s, cy - 36 * s), (cx + 32 * s, cy - 36 * s), (cx + 38 * s, cy + 6 * s),
            (cx + 26 * s, cy + 70 * s), (cx + 5 * s, cy + 70 * s), (cx, cy + 22 * s),
            (cx - 5 * s, cy + 70 * s), (cx - 26 * s, cy + 70 * s), (cx - 38 * s, cy + 6 * s)]
    for shape in (head, body):
        solid(img, shape, (2, 2, 3))
        gp.ink(img, shape + shape[:1], 6, 10, BONE, wobble=0.9, pressure=True)
    return head, body


def holes():
    """The Enigma of Amigara Fault, engraved rather than filled: a dark stele with a thin bone edge and three
    person-shaped holes cut into it, the middle one bleeding. A pale slab was a big bright block that had
    nothing to do with the rest of the bar; a dark stone with a fine edge is what the sheet's own art is."""
    img = canvas()
    slab = [(CX - 88, 40), (CX + 84, 34), (CX + 94, 300), (CX + 82, 606), (CX - 84, 610), (CX - 96, 320)]
    solid(img, slab, SLAB)
    gp.ink(img, slab + slab[:1], 8, 15, BONE, wobble=1.6, pressure=True)
    gp.ink(img, [(x + 9, y + 7) for x, y in slab] + [(slab[0][0] + 9, slab[0][1] + 7)], 3, 5, DIM, wobble=1.2, pressure=True)
    for i, cy in enumerate((168, 348, 522)):
        human_hole(img, CX + (-3, 4, -1)[i], cy, 0.8)
    gp.ink(img, [(CX + 30, 318), (CX + 44, 356), (CX + 36, 396)], 6, 12, BLOOD, wobble=1.0, pressure=True)
    solid(img, ellipse(CX + 44, 404, 9, 13), BLOOD)
    return img


def teeth():
    """A jaw of fangs on a slim spine, both sides at once: drawn as thin bone outlines around dark teeth, red
    only at the root, not as solid pale diamonds."""
    img = canvas()
    spine = gp.wave(CX, 40, CX, 606, 5, 1.4)
    gp.ink(img, spine, 10, 16, DIM, wobble=0.8, pressure=True)
    rng = random.Random(52)
    y = 76
    while y < 590:
        base_h = rng.uniform(22, 30)
        x = CX + rng.uniform(-3, 3)
        for side in (1, -1):
            ln = rng.uniform(64, 88)
            tip = (x + side * ln, y + rng.uniform(-10, 10))
            tooth = [(x, y - base_h), tip, (x, y + base_h)]
            solid(img, tooth, (24, 26, 30))
            gp.ink(img, tooth + tooth[:1], 6, 10, BONE, wobble=0.6, pressure=True)
        gp.ImageDraw.Draw(img).ellipse((x - 11, y - 11, x + 11, y + 11), fill=BLOOD + (255,))
        y += rng.uniform(70, 82)
    return img


RUST_DEEP = (96, 50, 22)


def chain():
    """A thin rusted chain hanging from a hook, the fog town's own iron: slim links alternating a wide oval
    with a narrow edge-on one, a thread of rust running off them, the last link torn open and bleeding.
    Thin on purpose -- the sheet's linework is fine, and a fat chain was the one thing on the seal that
    looked like it came from somewhere else."""
    img = canvas()
    rng = random.Random(17)
    hook = gp.arc(CX, 62, 30, 30, math.radians(210), math.radians(500), 28)
    gp.ink(img, hook, 9, 14, DIM, wobble=0.8, pressure=True)
    y = 132
    for k in range(6):
        wide = k % 2 == 0
        rx, ry = (38, 46) if wide else (13, 46)
        pts = ellipse(CX, y, rx, ry)
        gp.ink(img, pts + pts[:1], 10, 15, BONE if wide else DIM, wobble=1.0, pressure=True)
        gp.ink(img, [(px, py) for px, py in pts[len(pts) // 8:len(pts) // 3]], 5, 8, RUST, wobble=0.8, pressure=True)
        if rng.random() < 0.75:
            dx = rng.uniform(-rx * 0.6, rx * 0.6)
            gp.ink(img, [(CX + dx, y + ry - 4), (CX + dx + rng.uniform(-3, 3), y + ry + rng.uniform(22, 40))],
                   4, 8, RUST, wobble=0.6, pressure=True)
        y += 84
    gp.ink(img, [(CX - 20, y - 60), (CX + 6, y - 22)], 7, 12, BLOOD, wobble=1.0, pressure=True)
    solid(img, ellipse(CX + 8, y - 12, 8, 12), BLOOD)
    return img


def static_():
    """Interference, kept light: a handful of thin dashes of different lengths, one hairline of blood."""
    img = canvas()
    rng = random.Random(88)
    y = 70
    while y < 590:
        w = rng.uniform(50, 150)
        x = CX + rng.uniform(-25, 25) - w / 2
        h = rng.uniform(3, 6)
        col = BONE if rng.random() < 0.6 else DIM
        solid(img, [(x, y - h / 2), (x + w, y - h / 2), (x + w, y + h / 2), (x, y + h / 2)], col)
        y += rng.uniform(58, 84)
    solid(img, [(CX - 90, 318), (CX + 90, 318), (CX + 90, 322), (CX - 90, 322)], BLOOD)
    return img


def fog():
    """Fog as it is: layered soft noise stretched into vertical streaks, thick in the middle of the stem and
    thinning to nothing at both ends and at the sides, with a dim red glow buried in it."""
    import numpy as np
    from fogfield import fbm, smooth
    n = fbm(S, S, seed=44, sx=0.55, base=110)
    dens = 0.35 + 0.65 * smooth(n, 0.2, 0.85)
    yy = np.linspace(0, 1, S)[:, None]
    xx = np.linspace(-1, 1, S)[None, :]
    prof = np.exp(-((xx - 0.0) / 0.42) ** 2) * (np.sin(np.pi * np.clip((yy - 0.06) / 0.88, 0, 1)) ** 0.7)
    a = (dens * prof * 200).astype(np.uint8)
    img = Image.new("RGBA", (S, S), BONE + (0,))
    img.putalpha(Image.fromarray(a))
    glow = Image.new("RGBA", (S, S), BLOOD + (255,))
    glow.putalpha(gp.gradient(S, CX, 330, 75, inner=70, outer=0))
    img.alpha_composite(glow)
    return img


DECOR = {"veins": veins, "thorns": thorns, "curls": curls, "hair": hair, "drips": drips, "eyes": eyes,
         "cracks": cracks, "stitches": stitches, "holes": holes, "teeth": teeth, "chain": chain, "static": static_,
         "fog": fog}


def finish(img: Image.Image, seed: int, wear: float = 0.35) -> Image.Image:
    if wear > 0:
        img = gp.wear(img, wear, seed=seed)
    box = img.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    img = img.crop(box)
    # scale so the height is 512px, then pad a little
    k = 512 / img.height
    img = img.resize((max(1, round(img.width * k)), 512), Image.LANCZOS).filter(ImageFilter.UnsharpMask(1.2, 70, 2))
    out = Image.new("RGBA", (img.width + 24, 536), (0, 0, 0, 0))
    out.alpha_composite(img, (12, 12))
    return out


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    for i, (name, fn) in enumerate(DECOR.items()):
        finish(fn(), 70 + i, 0 if name in ("eyes", "fog") else 0.35).save(OUT / f"{name}.png")
    print(f"wrote {len(DECOR)} decorations -> {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

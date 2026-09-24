"""An eye drawn in code: the stand-in gen-eyefx.py uses when the Uzumaki panel is not on this machine.

  remina  the eye of the planet on the Remina mark: a flat white almond, a red iris ringed in ink, a black slit
          pupil, one small highlight. Same geometry as gen-marks.py remina().

Drawn 4x and scaled down so the lines stay clean at the 18-34 px they end up at.
"""

from __future__ import annotations

from PIL import Image, ImageDraw

BONE = (199, 204, 209)
BLOOD = (196, 22, 42)
INK = (10, 10, 12)
SS = 4


def bez(p0, p1, p2, p3, n=40):
    out = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        out.append((u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0],
                    u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1]))
    return out


def almond(w, h, top=1.0, bottom=1.0, skew=0.0):
    """Outline of an eye `w` wide and `h` tall centred on (0,0). `skew` lifts the outer (right) corner."""
    L, R = (-w / 2, 0.0), (w / 2, -skew * h)
    up = bez(L, (-w * 0.2, -h * 0.62 * top), (w * 0.2, -h * 0.62 * top), R)
    dn = bez(R, (w * 0.2, h * 0.62 * bottom), (-w * 0.2, h * 0.62 * bottom), L)
    return up + dn[1:]


def _shift(pts, cx, cy, k):
    return [(cx + x * k, cy + y * k) for x, y in pts]


def remina(size: int, iris=BLOOD, veins=False, open_: float = 1.0, glow=False) -> Image.Image:
    """A `size` x size/2-ish square canvas holding one Remina eye."""
    k = SS
    W = size * k
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = W / 2
    ew, eh = W * 0.92, W * 0.19 * max(0.12, open_)
    shape = _shift(almond(ew, eh / 0.465), c, c, 1)
    d.polygon(shape, fill=BONE + (255,))
    # clip the iris to the almond
    layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    r = eh * 1.02
    ld.ellipse((c - r, c - r, c + r, c + r), fill=iris + (255,), outline=INK + (255,), width=max(2, int(W * 0.022)))
    ld.ellipse((c - r * 0.2, c - r * 0.78, c + r * 0.2, c + r * 0.78), fill=INK + (255,))
    ld.ellipse((c - r * 0.42, c - r * 0.5, c - r * 0.42 + r * 0.16, c - r * 0.5 + r * 0.16), fill=(240, 240, 242, 255))
    if veins:
        for dy in (-0.55, -0.15, 0.3, 0.6):
            ld.line([(c - ew * 0.5, c + eh * dy), (c - r * 1.05, c + eh * dy * 0.5)], fill=BLOOD + (255,), width=max(2, int(W * 0.012)))
            ld.line([(c + ew * 0.5, c + eh * dy), (c + r * 1.05, c + eh * dy * 0.5)], fill=BLOOD + (255,), width=max(2, int(W * 0.012)))
    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).polygon(shape, fill=255)
    layer.putalpha(Image.composite(layer.getchannel("A"), Image.new("L", (W, W), 0), mask))
    img.alpha_composite(layer)
    d = ImageDraw.Draw(img)
    d.line(shape + [shape[0]], fill=INK + (255,), width=max(3, int(W * 0.03)), joint="curve")
    return img.resize((size, size), Image.LANCZOS)

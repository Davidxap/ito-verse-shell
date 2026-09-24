#!/usr/bin/env python3
"""The eyes the 'Eyes' media effect draws, and the ones the matching seal decoration stacks.

  eyes    the inked eye out of the Uzumaki panel (bar/modules/ito-art/panels/eye.png, cut from a reference the
          user supplied): feathered at its edges so it floats on the bar, and a bloodshot twin.

    gen-eyefx.py   writes bar/modules/ito-art/eyefx/{eyes,eyes-red}.png
"""

from pathlib import Path
import sys

import numpy as np
from PIL import Image

ART = Path(__file__).resolve().parent.parent / "bar" / "modules" / "ito-art"
OUT = ART / "eyefx"
BONE = (199, 204, 209)
BLOOD = (196, 22, 42)


def panel_eye(red: bool = False, width: int = 640) -> Image.Image:
    src = ART / "panels" / "eye.png"
    if not src.exists():                                   # a fresh clone has no third-party panel: use Remina's eye
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        import eyeart
        return eyeart.remina(width, veins=red)
    im = Image.open(src).convert("RGBA")
    k = width / im.width
    im = im.resize((width, max(1, round(im.height * k))), Image.LANCZOS)
    w, h = im.size
    y, x = np.mgrid[0:h, 0:w]
    r = np.hypot((x - w / 2) / (w / 2), (y - h / 2) / (h / 2))
    feather = np.clip((1.0 - r) / 0.28, 0, 1)              # the edge of the panel dissolves instead of showing a frame
    a = np.asarray(im.getchannel("A")).astype(float) * feather
    rgba = np.asarray(im).copy()
    if red:                                                # bloodshot: the light strokes take the blood tone
        lum = rgba[..., 0].astype(float) / 255
        for i, c in enumerate(BLOOD):
            rgba[..., i] = (c * (0.55 + 0.45 * lum)).astype(np.uint8)
    rgba[..., 3] = a.astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    panel_eye().save(OUT / "eyes.png")
    panel_eye(red=True).save(OUT / "eyes-red.png")
    print("wrote", OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

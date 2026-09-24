#!/usr/bin/env python3
"""Extract every icon from the design sheet at NATIVE resolution, with real alpha.

The earlier extraction was done by hand: cells came out shifted, filename captions
came along inside the PNGs, and everything was squeezed into a 64px canvas. The sheet
itself draws its icons at about 70-86px, so that squeeze threw pixels away and cropped
some art (the bottom stroke of the Tomie seal). This reads them properly:

  1. ImageMagick connected-components on an ink mask, dilated a little so the
     fragments of one icon merge while neighbouring icons stay apart;
  2. discard captions and headings (short text lines), section rules, and any
     component nested inside a bigger one (the inner dot of a ring);
  3. per row, order left to right and name them from the design's own layout;
  4. crop each from the ORIGINAL pixels and turn luminance into alpha, so the art sits
     on any background instead of dragging a black rectangle along.

    extract-sheet.py            write assets/native/
    extract-sheet.py --check    report counts per row, write nothing
"""

import argparse
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
SHEET = REPO / "assets" / "baseAssets" / "assets.png"
OUT = REPO / "assets" / "native"

# Rows as printed on the sheet: (y range, [(category, [names...]), ...]).
ROWS = [
    ((60, 215), [("workspaces", ["workspace-1", "workspace-2", "workspace-3", "workspace-4",
                                 "workspace-5", "workspace-urgent"]),
                 ("workspace-indicators", ["indicator-inactive", "indicator-active",
                                           "indicator-urgent", "indicator-empty"]),
                 ("workspace-labels", ["ws-1", "ws-2", "ws-3", "ws-4", "ws-5"])]),
    ((225, 405), [("system", ["system-normal", "system-hover", "system-active", "system-urgent"]),
                  ("status-eyes", ["eye-normal", "eye-red", "eye-closed", "eye-outline", "eye-bleeding"]),
                  ("tomie", ["tomie-red", "tomie-white", "tomie-mark"]),
                  ("network", ["wifi", "wifi-off", "wifi-weak", "wifi-connecting"])]),
    ((408, 570), [("battery", ["battery-full", "battery-75", "battery-50", "battery-25",
                               "battery-low", "battery-critical"]),
                  ("audio", ["volume", "volume-low", "volume-muted", "volume-high"]),
                  ("bluetooth", ["bluetooth", "bluetooth-off", "bluetooth-connecting"]),
                  ("brightness", ["brightness-high", "brightness-low"])]),
    ((572, 725), [("media", ["media-prev", "media-play", "media-next", "media-pause",
                             "media-stop", "media-shuffle", "media-repeat"]),
                  ("notifications", ["notification", "notification-active",
                                     "notification-muted", "notification-error"]),
                  ("quickshell", ["quickshell-normal", "quickshell-hover", "quickshell-active"]),
                  ("calendar", ["calendar", "calendar-active"])]),
    ((730, 850), [("devices", ["computer", "drive", "usb", "sd-card", "disk"]),
                  ("places", ["home", "desktop", "documents", "downloads", "pictures",
                              "music", "videos", "trash"]),
                  ("apps", ["browser", "terminal", "editor", "settings", "store"])]),
    # divider.png is a bare rule and is dropped by the rule filter, so it has no slot here.
    ((855, 1000), [("misc", ["corner", "blood-splatter", "paper-texture", "screentone", "grain"]),
                   ("cursor", ["cursor-normal", "cursor-hover", "cursor-text", "cursor-move",
                               "cursor-resize", "cursor-not-allowed"]),
                   ("fastfetch", ["figure", "logo", "logo-small"])]),
]

MIN_ICON_H = 20      # captions and headings are 13-17px tall
MIN_ICON_W = 12
MIN_AREA = 250
BLACK_LEVEL = 14     # the sheet's near-black background


def components() -> list[tuple[int, int, int, int]]:
    """(x, y, w, h) of every merged ink blob on the sheet."""
    out = subprocess.run(
        ["magick", str(SHEET), "-colorspace", "Gray", "-threshold", "12%",
         "-morphology", "Dilate", "Disk:3",
         "-define", "connected-components:verbose=true",
         "-define", "connected-components:area-threshold=60",
         "-connected-components", "8", "null:"],
        capture_output=True, text=True, check=True).stdout
    boxes = []
    for line in out.splitlines()[1:]:
        parts = line.split()
        if len(parts) < 4 or "x" not in parts[1] or "+" not in parts[1]:
            continue
        w, h, x, y = (int(v) for v in parts[1].replace("x", "+").split("+"))
        boxes.append((x, y, w, h, float(parts[3])))
    return boxes


# Regions whose fragments belong to ONE icon: any component touching a region is merged
# into the union. Found by overlaying the detected boxes on the sheet and looking.
MERGE = [
    ("eye-outline: the ring and its two pupil fragments", (670, 268, 752, 345)),
    ("tomie-red: the 富 and the 江 come out as two components", (900, 270, 945, 350)),
    ("fastfetch figure: the portrait and its loose hair strands", (1184, 858, 1276, 978)),
    ("blood-splatter: the big splat and the smaller one above it", (180, 885, 262, 980)),
]

# Regions that hold something that is not an icon.
DROP = [
    ("vertical panel rule beside the fastfetch figure", (1160, 858, 1184, 975)),
]


def touches(box, region):
    x, y, w, h = box
    return not (x + w < region[0] or x > region[2] or y + h < region[1] or y > region[3])


def icon_boxes() -> list[tuple[int, int, int, int]]:
    raw = components()
    kept = []
    for x, y, w, h, area in raw:
        if w > 1400 or h < MIN_ICON_H or w < MIN_ICON_W or area < MIN_AREA:
            continue
        if w >= 10 * h or h >= 10 * w:
            continue
        if w > 150 and h < 25:          # section headings ("TOMIE SYMBOLS", "NOTIFICATIONS")
            continue
        if 60 <= y + h / 2 <= 215 and y >= 150 and h < 40:
            continue                     # two-line captions under the workspace indicators
        kept.append((x, y, w, h))

    kept = [b for b in kept if not any(touches(b, r) for _, r in DROP)]

    for _, region in MERGE:
        group = [b for b in kept if touches(b, region)]
        if len(group) > 1:
            x0 = min(b[0] for b in group); y0 = min(b[1] for b in group)
            x1 = max(b[0] + b[2] for b in group); y1 = max(b[1] + b[3] for b in group)
            kept = [b for b in kept if b not in group] + [(x0, y0, x1 - x0, y1 - y0)]

    def inside(a, b):  # a nested in b
        return a != b and a[0] >= b[0] - 2 and a[1] >= b[1] - 2 \
            and a[0] + a[2] <= b[0] + b[2] + 2 and a[1] + a[3] <= b[1] + b[3] + 2
    return [a for a in kept if not any(inside(a, b) for b in kept)]


def to_rgba(img: Image.Image) -> Image.Image:
    """Luminance becomes alpha; colour is un-multiplied so dim ink keeps its hue."""
    px = np.asarray(img.convert("RGB")).astype(np.float32)
    peak = px.max(axis=2)
    alpha = np.clip((peak - BLACK_LEVEL) / (200.0 - BLACK_LEVEL), 0.0, 1.0)
    safe = np.maximum(alpha, 1e-3)[..., None]
    rgb = np.clip(px / safe, 0, 255)
    out = np.dstack([rgb, alpha * 255]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    boxes = icon_boxes()
    sheet = Image.open(SHEET)
    plan, problems = [], []

    print(f"{'row':<5}{'found':>7}{'expected':>10}")
    for index, ((top, bottom), groups) in enumerate(ROWS, 1):
        row = sorted([b for b in boxes if top <= b[1] + b[3] / 2 <= bottom], key=lambda b: b[0])
        names = [(cat, n) for cat, ns in groups for n in ns]
        print(f"r{index:<4}{len(row):>7}{len(names):>10}   {'ok' if len(row) == len(names) else 'MISMATCH'}")
        if len(row) != len(names):
            problems.append(index)
            print("      found:", " ".join(f"{b[2]}x{b[3]}@{b[0]}" for b in row))
            continue
        plan.extend(zip(row, names))

    if problems:
        print(f"\nrows {problems} do not match the sheet's layout; nothing written")
        return 1
    if args.check:
        return 0

    for (x, y, w, h), (category, name) in plan:
        pad = 3
        crop = sheet.crop((max(0, x - pad), max(0, y - pad), x + w + pad, y + h + pad))
        target = OUT / category
        target.mkdir(parents=True, exist_ok=True)
        to_rgba(crop).save(target / f"{name}.png")
    print(f"\nwrote {len(plan)} icons to {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env bash
# Render a QML scene offscreen to a PNG, without touching the user's desktop or shell.
#
#   render.sh [scene.qml] [out.png]        scenes live next to this script
#
# The scene must save its own image to /tmp/ito-lab/out.png and quit (see lab-mediafx.qml).
# Uses the software backend so the Canvas glyphs paint with no GPU or display.

set -euo pipefail
LAB="$(cd "$(dirname "$0")" && pwd)"
SCENE=${1:-lab-mediafx.qml}
OUT=${2:-/tmp/ito-lab/lab.png}
mkdir -p /tmp/ito-lab "$(dirname "$OUT")"
rm -f /tmp/ito-lab/out.png

QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  timeout 60 qml6 "$LAB/$SCENE" 2>&1 | grep -vE "^\s*$|propagateSizeHints|QFont::|Fontconfig" | head -20 || true

[[ -f /tmp/ito-lab/out.png ]] || { echo "render failed: the scene produced no image" >&2; exit 1; }
mv /tmp/ito-lab/out.png "$OUT"
echo "$OUT"

#!/usr/bin/env bash
# Run the ito.bar engine for a few seconds on a throwaway layout, report what
# happened, and ALWAYS put the user's shell back exactly as it was.
#
#   itobar-try.sh <backup-dir> [hold-seconds]
#
# <backup-dir> must hold RESTORE.sh and shell.json.LIVE-AT-BACKUP (made by the
# pre-itobar backup step). The restore runs from a trap, so it happens even if a
# step below fails or the script is interrupted.
#
# The test layout is deliberately tiny and uses only REGISTERED widgets
# (omarchy.workspaces, omarchy.tray, ito.clock, ito.audio). That isolates the
# question that matters - can the fork host stock and cloned widgets - from the
# Shibumi widgets, which have their own history of errors.

set -uo pipefail

BACKUP=${1:?usage: itobar-try.sh <backup-dir> [hold-seconds]}
HOLD=${2:-14}
# Optional JSON file {"left":[ids],"center":[ids],"right":[ids],"anchor":"id"} to test
# instead of the default four registered widgets.
LAYOUT_FILE=${ITOBAR_LAYOUT:-}
SHELL_JSON="$HOME/.config/omarchy/shell.json"
SCRATCH=${TMPDIR:-/tmp}
OUT="$SCRATCH/itobar-try"
mkdir -p "$OUT"

[[ -x $BACKUP/RESTORE.sh && -f $BACKUP/shell.json.LIVE-AT-BACKUP ]] \
  || { echo "error: $BACKUP is not a usable backup" >&2; exit 2; }

restored=0
restore() {
  (( restored )) && return
  restored=1
  echo
  echo "== restoring the original shell =="
  "$BACKUP/RESTORE.sh" >"$OUT/restore.log" 2>&1 </dev/null
  sleep 6
  python3 - "$BACKUP" <<'PY'
import json, pathlib, sys
live = json.loads((pathlib.Path.home()/".config/omarchy/shell.json").read_text())
was = json.loads((pathlib.Path(sys.argv[1])/"shell.json.LIVE-AT-BACKUP").read_text())
print("engine:", live["bar"]["id"], "| layout identical to the original:",
      live["bar"]["layout"] == was["bar"]["layout"])
PY
}
trap restore EXIT INT TERM

# -- build the throwaway layout from the user's own config -------------------
python3 "$(dirname "$0")/itobar-layout.py" "$BACKUP" "$SHELL_JSON" "$LAYOUT_FILE" || { echo "could not build the test layout"; exit 3; }

# -- boot the engine ---------------------------------------------------------
echo "== booting ito.bar (holding ${HOLD}s) =="
kill $(pgrep -f 'quickshe[l]l') 2>/dev/null || true
sleep 3
setsid omarchy-launch-shell >/dev/null 2>&1 </dev/null & disown
sleep "$HOLD"

pid=$(pgrep -f 'quickshe[l]l' | head -1)
echo "shell process: ${pid:-NONE}"

# -- what the engine says about itself --------------------------------------
echo
echo "== plugin state per the engine =="
omarchy-shell shell listPlugins >"$OUT/plugins.json" 2>/dev/null
python3 - "$OUT/plugins.json" <<'PY'
import json, sys
try:
    rows = json.load(open(sys.argv[1]))
except Exception as exc:
    print("listPlugins unreadable:", exc)
    sys.exit()
by = {r["id"]: r for r in rows}
# Only the bar's own flag is meaningful; widgets read as active=False even when drawn.
want = sorted(i for i in by if i.startswith(("ito.",)))
for name in want:
    row = by.get(name)
    if row is None:
        print(f"  {name:<24} MISSING")
    else:
        print(f"  {name:<24} enabled={row['enabled']}" + (f" active={row['active']}" if name == "ito.bar" else ""))
PY

# -- the journal, filtered to this boot -------------------------------------
echo
echo "== journal (this process) =="
journalctl --user --no-pager -n 6000 2>/dev/null | grep "omarchy-shell\[$pid\]" > "$OUT/journal.txt" || true
echo "lines: $(wc -l < "$OUT/journal.txt")"
echo "-- suite / marker / retire / ito.* --"
grep -iE "ito\.(bar|state)|ito-managed|retire|suite|payload" "$OUT/journal.txt" | grep -v IpcHandler | head -8 || true
echo "-- errors --"
grep -E "Error|TypeError|Cannot|Unable|failed|ReferenceError" "$OUT/journal.txt" | grep -v IpcHandler \
  | sed -E 's/^.*omarchy-shell\[[0-9]+\]: +//' | sort | uniq -c | sort -rn | head -10 || true

# -- a picture of the bar only ----------------------------------------------
omarchy capture screenshot fullscreen save >/dev/null 2>&1
shot=$(ls -t "$HOME"/Pictures/screenshot-*.png 2>/dev/null | head -1)
if [[ -n $shot ]]; then
  magick "$shot" -crop 2560x64+0+0 +repage "$OUT/bar.png" 2>/dev/null
  rm -f "$shot"   # the full capture can hold private windows
  echo
  echo "bar strip saved: $OUT/bar.png"
fi

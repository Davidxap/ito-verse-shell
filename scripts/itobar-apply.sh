#!/usr/bin/env bash
# Put the ito.bar engine live and LEAVE it there, with the way back printed.
#
#   itobar-apply.sh <backup-dir> [layout.json]
#
# itobar-try.sh runs the engine for a few seconds and restores; this one is for when the user
# wants to live with it. It builds shell.json from the backup's exact layout (itobar-layout.py),
# snapshots that as the itobar variant, restarts the shell and reports what the engine says.
# Only the bar changes: the theme and everything else stay as they were.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP=${1:?usage: itobar-apply.sh <backup-dir> [layout.json]}
LAYOUT=${2:-}
HOLD=${HOLD:-9}
OMARCHY="$HOME/.config/omarchy"

[[ -x $BACKUP/RESTORE.sh && -f $BACKUP/shell.json.LIVE-AT-BACKUP ]] || { echo "not a usable backup: $BACKUP" >&2; exit 2; }

python3 "$HERE/itobar-layout.py" "$BACKUP" "$OMARCHY/shell.json" "$LAYOUT"
cp "$OMARCHY/shell.json" "$OMARCHY/shell.itobar.json"           # the variant, before the engine rewrites it

kill $(pgrep -f 'quickshe[l]l') 2>/dev/null || true
sleep 3
setsid omarchy-launch-shell >/dev/null 2>&1 </dev/null & disown
sleep "$HOLD"

pid=$(pgrep -f 'quickshe[l]l' | head -1)
echo "shell: ${pid:-NOT RUNNING}"
if [[ -n ${pid:-} ]]; then
  journalctl --user --no-pager -n 6000 2>/dev/null | grep "omarchy-shell\[$pid\]" > /tmp/itobar-apply.journal || true
  echo "journal lines: $(wc -l < /tmp/itobar-apply.journal)   errors (excluding IPC noise):"
  grep -E "Error|TypeError|Cannot|Unable|ReferenceError" /tmp/itobar-apply.journal | grep -v IpcHandler \
    | sed -E 's/^.*omarchy-shell\[[0-9]+\]: +//' | sort | uniq -c | sort -rn | head -8 || true
fi
echo
echo "way back, exact:  $BACKUP/RESTORE.sh"

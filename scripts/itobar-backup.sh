#!/usr/bin/env bash
# Take a fresh backup of everything a live engine trial can disturb, and print its path.
#
# The rule: every live attempt starts from a NEW backup, because the
# shell-switch variants go stale and only this exact copy restores the user's layout.
# The backup carries its own RESTORE.sh, which puts back the live shell.json, the
# shell choice and relaunches the shell.

set -euo pipefail
DEST="/mnt/DATA/Themes/ito-verse/backups/pre-itobar-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEST"
cp -a ~/.config/omarchy/shell.json "$DEST/shell.json.LIVE-AT-BACKUP"
cp -a ~/.config/hypr/shell-choice "$DEST/shell-choice"
cp -a ~/.local/state/omarchy/current/theme.name "$DEST/theme.name"

cat > "$DEST/RESTORE.sh" <<'RESTORE'
#!/usr/bin/env bash
# Restores the exact state this backup captured.
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
cp -a "$D/shell.json.LIVE-AT-BACKUP" ~/.config/omarchy/shell.json
cp -a "$D/shell-choice" ~/.config/hypr/shell-choice
kill $(pgrep -f 'quickshe[l]l') 2>/dev/null || true
sleep 3
setsid omarchy-launch-shell >/dev/null 2>&1 </dev/null & disown
echo "restored: $(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.config/omarchy/shell.json')))['bar']['id'])")"
RESTORE
chmod +x "$DEST/RESTORE.sh"
echo "$DEST"

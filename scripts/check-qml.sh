#!/usr/bin/env bash
# The mistakes qmllint can catch before the shell is restarted: duplicate names, syntax errors, unknown ids.
# The panel pages only load when opened, so a broken one otherwise goes unnoticed until someone clicks on it.
#   scripts/check-qml.sh          lint the Control Centre pages and the shared components
set -u
cd "$(dirname "$0")/.."
bad=0
for f in bar/modules/cc/*.qml bar/modules/Ito*.qml; do
  out=$(timeout 30 qmllint "$f" 2>&1 | grep -E "Duplicat|Syntax|Unexpected|Expected|not defined|Cannot assign to non-existent|is not a" || true)
  if [[ -n $out ]]; then echo "$f"; echo "$out" | sed 's/^/    /'; bad=1; fi
done
[[ $bad -eq 0 ]] && echo "qml: no errors in the pages and shared components"
exit $bad

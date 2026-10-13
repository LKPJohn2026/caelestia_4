#!/usr/bin/env bash
# Cheap checks for the caelestia family (run by stage-for-test.sh).
#  1. `pragma Singleton` must come before the first `{` in the file. Quickshell's singleton pre-scan
#     stops at the first `{`, even inside a comment (Phase 2 bug: Colours loaded as a type, not a singleton).
#  2. No unported Caelestia imports under modules/caelestia (a qs.X.Y import whose X/Y directory doesn't exist).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../dots/.config/quickshell/ii"
fail=0
while IFS= read -r -d '' f; do
  if grep -q '^pragma Singleton' "$f"; then
    p=$(grep -bo '^pragma Singleton' "$f" | head -1 | cut -d: -f1)
    b=$(grep -bo '{' "$f" | head -1 | cut -d: -f1)
    if [[ -n "$b" && "$b" -lt "$p" ]]; then echo "LINT: '{' before 'pragma Singleton' in $f"; fail=1; fi
  fi
done < <(find modules/caelestia panelFamilies -name '*.qml' -print0)
# An import is unported when its qs.* path has no directory here (end-4's qs.services / qs.modules.common exist and
# are used on purpose by the assistant, overlay and adapters)
bad=$(grep -rnE '^\s*import\s+qs\.' --include='*.qml' modules/caelestia | grep -v 'caelestia4: keep' \
      | while IFS= read -r line; do
          mod=$(sed -E 's/.*import[[:space:]]+qs\.([A-Za-z0-9_.]+).*/\1/' <<<"$line")
          [[ -d "${mod//.//}" ]] || echo "$line"
        done || true)
[[ -z "$bad" ]] || { echo "LINT: unported imports:"; echo "$bad"; fail=1; }
[[ $fail -eq 0 ]] && echo "lint: OK"
exit $fail

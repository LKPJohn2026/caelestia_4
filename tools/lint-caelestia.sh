#!/usr/bin/env bash
# Cheap checks for the caelestia family (run by stage-for-test.sh).
#  1. `pragma Singleton` must come before the first `{` in the file. Quickshell's singleton pre-scan
#     stops at the first `{`, even inside a comment (Phase 2 bug: Colours loaded as a type, not a singleton).
#  2. No unported Caelestia imports (qs.components / qs.services / qs.utils / qs.modules.X) under modules/caelestia.
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
bad=$(grep -rnE '^\s*import\s+qs\.(components|services|utils|modules\.)' --include='*.qml' modules/caelestia \
      | grep -vE 'qs\.modules\.caelestia|caelestia4: keep' || true)
[[ -z "$bad" ]] || { echo "LINT: unported imports:"; echo "$bad"; fail=1; }
[[ $fail -eq 0 ]] && echo "lint: OK"
exit $fail

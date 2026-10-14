#!/usr/bin/env bash
# Rewrite Caelestia's internal QML imports so ported files live under
# end-4's tree at modules/caelestia/ without clashing with end-4's own qs.* names.
# (docs/dev/PLAN.md §3.2). Rewrites import lines only, in place. Idempotent.
#
#   qs.components[.x]  -> qs.modules.caelestia.components[.x]
#   qs.utils           -> qs.modules.caelestia.utils
#   qs.services        -> qs.modules.caelestia.adapters   (Caelestia-shaped facades over end-4 services)
#   qs.modules.<x>     -> qs.modules.caelestia.<x>
#   import Caelestia.* (C++ plugin) and quoted relative imports are left unchanged.
#   Lines ending in `// caelestia4: keep` are never rewritten (hand-written adapters importing end-4's own qs.services etc.).
#
# Usage: tools/port-imports.sh <file-or-dir>...   (only run on files under modules/caelestia/)
set -euo pipefail
[[ $# -ge 1 ]] || { echo "usage: $0 <file-or-dir>..." >&2; exit 2; }

find "$@" -type f -name '*.qml' -print0 | xargs -0 -r sed -i -E \
  -e '/\/\/\s*caelestia4:\s*keep\s*$/b' \
  -e '/^\s*import\s+qs\.modules\.caelestia(\.|\s|$)/b' \
  -e 's/^(\s*import\s+)qs\.components(\.|\s|$)/\1qs.modules.caelestia.components\2/;t' \
  -e 's/^(\s*import\s+)qs\.utils(\s|$)/\1qs.modules.caelestia.utils\2/;t' \
  -e 's/^(\s*import\s+)qs\.services(\s|$)/\1qs.modules.caelestia.adapters\2/;t' \
  -e 's/^(\s*import\s+)qs\.modules\./\1qs.modules.caelestia./'

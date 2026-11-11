#!/usr/bin/env bash
# Bring in newer upstream code, then rebuild and smoke-test. (docs/dev/PLAN.md Phase 10)
#   tools/sync-upstreams.sh caelestia <tag>             move third_party/caelestia-shell to a new tag
# end-4 is not merged: it is a vendored library whose commits are reviewed and picked with tools/sync-end4.sh.
# Before running: take a snapshot (sudo snapper create -d "caelestia_4 sync ...").
# After a Caelestia bump: re-copy changed upstream files into modules/caelestia/ by hand,
# run tools/port-imports.sh on them, and update the version pins in build-caelestia-plugin.sh.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# A wholesale merge would bring back everything removed here since end-4 became vendored (2026-10-27)
if [[ "${1:-}" == end4 ]]; then
  echo "end-4 is synced with tools/sync-end4.sh (review, pick SHA..., mark), not merged." >&2
  exit 1
fi

[[ -z "$(git status --porcelain)" ]] || { echo "Working tree not clean; commit or stash first." >&2; exit 1; }

case "${1:-}" in
  caelestia)
    tag="${2:?Caelestia tag required, e.g. v2.6.0}"
    # -S: the squash commit must be signed too (ruleset secure-main rejects unsigned commits)
    git subtree pull -S --prefix third_party/caelestia-shell https://github.com/caelestia-dots/shell.git "$tag" --squash \
      -m "Update vendored caelestia-dots/shell to $tag"
    echo ">> Update VERSION/GIT_REVISION in tools/build-caelestia-plugin.sh for $tag"
    ;;
  *)
    sed -n '2,7p' "$0"; exit 2 ;;
esac

./tools/build-caelestia-plugin.sh
QT_QPA_PLATFORM=offscreen QML_IMPORT_PATH="$HOME/.local/lib/qt6/qml" \
  timeout 15 qs -p tools/tests/plugin-smoke --no-color 2>&1 | grep -q 'SMOKE OK' \
  && echo "Plugin smoke test: OK" || { echo "Plugin smoke test: FAILED" >&2; exit 1; }

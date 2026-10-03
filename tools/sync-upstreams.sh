#!/usr/bin/env bash
# Bring in newer upstream code, then rebuild and smoke-test. (PLAN.md Phase 10)
#   tools/sync-upstreams.sh end4 <commit-or-ref>        merge end-4/dots-hyprland at a pinned ref
#   tools/sync-upstreams.sh caelestia <tag>             move third_party/caelestia-shell to a new tag
# Before running: take a snapshot (sudo snapper create -d "caelestia_4 sync ...").
# After a Caelestia bump: re-copy changed upstream files into modules/caelestia/ by hand,
# run tools/port-imports.sh on them, and update the version pins in build-caelestia-plugin.sh.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

[[ -z "$(git status --porcelain)" ]] || { echo "Working tree not clean; commit or stash first." >&2; exit 1; }

case "${1:-}" in
  end4)
    ref="${2:?end-4 commit or ref required}"
    git remote get-url upstream >/dev/null 2>&1 || git remote add upstream https://github.com/end-4/dots-hyprland.git
    git fetch upstream
    git merge --no-ff -m "Merge end-4/dots-hyprland @ $ref" "$ref"
    git submodule update --init
    ;;
  caelestia)
    tag="${2:?Caelestia tag required, e.g. v2.6.0}"
    git subtree pull --prefix third_party/caelestia-shell https://github.com/caelestia-dots/shell.git "$tag" --squash \
      -m "Update vendored caelestia-dots/shell to $tag"
    echo ">> Update VERSION/GIT_REVISION in tools/build-caelestia-plugin.sh for $tag"
    ;;
  *)
    sed -n '2,8p' "$0"; exit 2 ;;
esac

./tools/build-caelestia-plugin.sh
QT_QPA_PLATFORM=offscreen QML_IMPORT_PATH="$HOME/.local/lib/qt6/qml" \
  timeout 15 qs -p tools/tests/plugin-smoke --no-color 2>&1 | grep -q 'SMOKE OK' \
  && echo "Plugin smoke test: OK" || { echo "Plugin smoke test: FAILED" >&2; exit 1; }

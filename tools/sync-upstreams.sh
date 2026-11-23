#!/usr/bin/env bash
# Bring in newer upstream code, then rebuild and smoke-test.
#   tools/sync-upstreams.sh caelestia <tag>             move third_party/caelestia-shell to a new tag
# end-4 is not merged: it is a vendored library whose commits are reviewed and picked with tools/sync-end4.sh.
# Before running: take a snapshot (sudo snapper create -d "caelestia_4 sync ...").
# After a Caelestia bump: re-copy changed upstream files into modules/caelestia/ by hand,
# run tools/port-imports.sh on them, and update the version pins in build-caelestia-plugin.sh.
# A repo with no licence file at the top of its tree is refused; ALLOW_UNLICENSED=1 overrides (see require_licence).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# A wholesale merge would bring back everything removed here since end-4 became vendored (2026-10-27)
if [[ "${1:-}" == end4 ]]; then
  echo "end-4 is synced with tools/sync-end4.sh (review, pick SHA..., mark), not merged." >&2
  exit 1
fi

[[ -z "$(git status --porcelain)" ]] || { echo "Working tree not clean; commit or stash first." >&2; exit 1; }

# Code without a licence can't be redistributed, and everything vendored here so far is GPL-3.0. Before anything is
# merged this looks at the top of the fetched tree for a LICENSE, LICENCE or COPYING file (any extension) or a REUSE
# LICENSES/ directory holding one. Only a regular file with something in it counts: not a link (whose target could be
# anything, or nothing) and not an empty file or one of only blanks. It prints the commit it checked, and that commit,
# not the ref, is what gets merged.
# ALLOW_UNLICENSED=1 is for a repo whose licence is stated somewhere else: write down where in docs/feature-comparison.md.
require_licence() {
  local url="$1" ref="$2" rev tree
  git fetch --quiet --no-tags "$url" "$ref" >&2 || { echo "Could not fetch $ref from $url" >&2; exit 1; }
  # This runs inside $(...), where bash drops set -e, hence the explicit exits
  rev=$(git rev-parse 'FETCH_HEAD^{commit}') || exit 1
  # Read the whole listing first: grep -q on a pipe can SIGPIPE git under pipefail and fail a good repo.
  # -l: "mode type object size<TAB>path"; 100644/100755 are files (120000 is a link, 160000 a submodule)
  tree=$(git ls-tree -l "$rev" && git ls-tree -l -r "$rev" -- LICENSES) || exit 1
  local obj
  # each candidate's object: a file, by name, with something in it; then one with more than blanks in it
  while read -r obj; do
    [[ -n $(git cat-file blob "$obj" | tr -d '[:space:]') ]] && { echo "$rev"; return 0; }
  done < <(awk -F'\t' '{ split($1, m, / +/) }
      (m[1] == "100644" || m[1] == "100755") && m[2] == "blob" && m[4] > 0 &&
        (tolower($2) ~ /^(licen[cs]e|copying)([.-].*)?$/ || $2 ~ /^LICENSES\/[^\/]+$/) { print m[3] }' <<<"$tree")
  if [[ "${ALLOW_UNLICENSED:-}" == 1 ]]; then
    echo "!! $url at $ref has no licence file; vendoring anyway (ALLOW_UNLICENSED=1)" >&2
    echo "$rev"; return 0
  fi
  echo "$url at $ref has no licence file (LICENSE, LICENCE, COPYING or LICENSES/: a file, not blank, not a link)," >&2
  echo "so it is not vendored." >&2
  echo "Ask upstream to add one, or set ALLOW_UNLICENSED=1 if its licence is stated elsewhere." >&2
  exit 1
}

case "${1:-}" in
  caelestia)
    tag="${2:?Caelestia tag required, e.g. v2.6.0}"
    rev=$(require_licence https://github.com/caelestia-dots/shell.git "$tag")
    # Merge the commit the licence check saw, so a tag moved in between can't slip in.
    # -S: the squash commit must be signed too (ruleset secure-main rejects unsigned commits)
    git subtree merge -S --prefix third_party/caelestia-shell "$rev" --squash \
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

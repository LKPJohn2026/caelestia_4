# shellcheck shell=bash
# Sourced by tools/compile-check.sh and tools/tests/nexus-shot/run.sh (run from the repo root).
# fill_submodules DEST: DEST is a copy of dots/.config/quickshell/ii. A linked worktree, fresh clone or git archive has
# its submodules empty, and with shapes/*.js missing Qt 6.12's type loader segfaults on this tree instead of reporting an
# error. Fill the copy at the pinned commit, from the objects the main checkout already has (no network, the tree is
# left alone); return 2 if there is no way to.
fill_submodules() {
  local dest=$1 key path name mod sha
  while read -r key path; do
    [[ "$path" == dots/.config/quickshell/ii/* ]] || continue
    [[ -n "$(ls -A "$path" 2>/dev/null)" ]] && continue
    name=${key#submodule.}; name=${name%.path}
    mod="$(git rev-parse --git-common-dir 2>/dev/null)/modules/$name"
    sha=$(git rev-parse ":$path" 2>/dev/null)
    if [[ -z "$sha" ]] || ! git -C "$mod" cat-file -e "$sha^{commit}" 2>/dev/null; then
      echo "submodule $path is empty and its pinned commit isn't available here."
      echo "In a git checkout run: git submodule update --init -- $path"
      return 2
    fi
    git -C "$mod" archive "$sha" | tar -x -C "$dest/${path#dots/.config/quickshell/ii/}"
  done < <(git config -f .gitmodules --get-regexp '\.path$')
}

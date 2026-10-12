#!/usr/bin/env bash
# caelestia4: merge end-4 upstream (github.com/end-4/dots-hyprland) into this fork.
# Paths we removed on purpose (REMOVED below) would otherwise come back or stop the merge:
#  - upstream edits to a removed file  -> modify/delete conflict  -> resolved by keeping it removed
#  - upstream adds a file under a removed directory -> merges cleanly -> removed again after the merge
# Anything else that conflicts is left for you to resolve (the script stops and lists it).
# Usage: tools/sync-end4.sh        Author: git config of this repo (John La).
set -euo pipefail
cd "$(dirname "$0")/.."

REMOVED=(
  dots/.config/quickshell/ii/modules/waffle            # Waffle panel family (removed 2026-10-11)
  dots/.config/quickshell/ii/panelFamilies/WaffleFamily.qml
  dots/.config/quickshell/ii/modules/common/widgets/CalendarView.qml  # only used by Waffle
)
is_removed() { local p; for p in "${REMOVED[@]}"; do [[ "$1" == "$p" || "$1" == "$p"/* ]] && return 0; done; return 1; }
GIT=(git -c user.name="John La" -c user.email=john.pla1998@gmail.com)

git diff --quiet && git diff --cached --quiet || { echo "working tree not clean" >&2; exit 1; }
git fetch -q upstream
echo "upstream commits to merge: $(git rev-list --count HEAD..upstream/main)"

if ! "${GIT[@]}" merge --no-edit upstream/main; then
  while IFS= read -r f; do
    is_removed "$f" && git rm -q --ignore-unmatch -- "$f" && echo "kept removed: $f"
  done < <(git diff --name-only --diff-filter=U)
  if [[ -n "$(git diff --name-only --diff-filter=U)" ]]; then
    echo "conflicts left to resolve:"; git diff --name-only --diff-filter=U; exit 1
  fi
  "${GIT[@]}" commit --no-edit -q
fi

# Files upstream added under removed paths
for p in "${REMOVED[@]}"; do
  if [[ -e "$p" ]]; then git rm -rq -- "$p"; echo "removed again: $p"; fi
done
git diff --cached --quiet || "${GIT[@]}" commit -qm "sync-end4: keep removed paths removed"
echo "done: $(git log -1 --format='%h %s')"

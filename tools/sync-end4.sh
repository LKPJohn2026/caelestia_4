#!/usr/bin/env bash
# caelestia4: end-4 (github.com/end-4/dots-hyprland) is a vendored library here, not an upstream to merge (decided
# 2026-10-27: the shell is Caelestia's; what's left of end-4 is the services, scripts and Hyprland config it runs on).
# Its new commits are reviewed and picked one by one instead of merged:
#   tools/sync-end4.sh [review]    upstream commits since the last review, with the files each touches that still
#                                  exist here (kept) and the ones removed here; open upstream PRs if gh is set up
#   tools/sync-end4.sh pick SHA... cherry-pick (-x) those commits; their changes to files removed here stay removed
#   tools/sync-end4.sh mark [SHA]  record upstream/main (or SHA) as reviewed (tools/end4-reviewed; commit it)
# Commits use this repo's git identity (git config user.name / user.email).
set -euo pipefail
cd "$(dirname "$0")/.."

MARK=tools/end4-reviewed
git fetch -q upstream
reviewed=$(cat "$MARK" 2>/dev/null || git merge-base HEAD upstream/main)

review() {
  local n
  n=$(git rev-list --count "$reviewed..upstream/main")
  echo "end-4 commits since the last review ($(git log -1 --format='%h %cs' "$reviewed")): $n"
  git log --reverse --format='%H %h %cs %s' "$reviewed..upstream/main" | while read -r full short date subject; do
    local kept=() gone=()
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      if [[ -e "$f" ]]; then kept+=("$f"); else gone+=("$f"); fi
    done < <(git diff-tree --no-commit-id --name-only -r "$full")
    echo
    echo "$short $date $subject"
    ((${#kept[@]})) && printf '    kept:    %s\n' "${kept[@]}"
    ((${#gone[@]})) && printf '    removed: %s\n' "${gone[@]}"
  done
  if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
    echo
    echo "open end-4 PRs (newest first):"
    gh pr list -R end-4/dots-hyprland --state open --limit 15 --json number,updatedAt,title \
      --jq '.[] | "  #\(.number)  \(.updatedAt[:10])  \(.title)"'
  fi
  ((n)) && echo && echo "pick: tools/sync-end4.sh pick SHA...   then: tools/sync-end4.sh mark"
  return 0
}

pick() {
  git diff --quiet && git diff --cached --quiet || { echo "working tree not clean" >&2; exit 1; }
  local sha f
  for sha in "$@"; do
    sha=$(git rev-parse --verify "$sha^{commit}")
    # Applied without committing, then committed as this repo's identity (signed) with the source named in the message
    if ! git cherry-pick --no-commit "$sha"; then
      # A change to a file removed here (modify/delete): keep it removed
      while IFS= read -r f; do
        if ! git cat-file -e "HEAD:$f" 2>/dev/null; then git rm -q -- "$f" && echo "kept removed: $f"; fi
      done < <(git diff --name-only --diff-filter=U)
      if [[ -n "$(git diff --name-only --diff-filter=U)" ]]; then
        echo "conflicts left to resolve, then commit (the message is in $(git rev-parse --git-path MERGE_MSG)):"
        git diff --name-only --diff-filter=U; exit 1
      fi
    fi
    if git diff --cached --quiet; then
      git cherry-pick --quit 2>/dev/null || true
      echo "skipped ${sha:0:9}: nothing to apply (already here, or it only touches files removed here)"
      continue
    fi
    git cherry-pick --quit 2>/dev/null || true
    git commit -S -q -m "$(git log -1 --format=%s "$sha")" \
      -m "Picked from end-4/dots-hyprland@$sha ($(git log -1 --format='%an, %cs' "$sha"))."
    echo "picked: $(git log -1 --format='%h %s')"
  done
}

mark() {
  git rev-parse --verify -q "${1:-upstream/main}^{commit}" > "$MARK"
  echo "reviewed up to $(git log -1 --format='%h %cs %s' "$(cat "$MARK")") ($MARK: commit it)"
}

cmd=${1:-review}
shift || true
case "$cmd" in
  review) review ;;
  pick) (($#)) || { echo "usage: $0 pick SHA..." >&2; exit 1; }; pick "$@" ;;
  mark) mark "$@" ;;
  *) sed -n '2,9p' "$0" >&2; exit 1 ;;
esac

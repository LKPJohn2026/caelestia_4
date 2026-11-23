#!/usr/bin/env bash
# caelestia4: end-4 (github.com/end-4/dots-hyprland) is a vendored library here, not an upstream to merge (decided
# 2026-10-27: the shell is Caelestia's; what's left of end-4 is the services, scripts and Hyprland config it runs on).
# Its new commits are reviewed and picked one by one instead of merged:
#   tools/sync-end4.sh [review]    upstream commits since the last review, with the files each touches that still
#                                  exist here (kept), removed here, or new upstream; open upstream PRs if gh is set up
#   tools/sync-end4.sh pick SHA... apply those commits ("Picked from" names each); files removed here stay removed;
#                                  only plain files under dots/ and dots-extra/ go in without asking: anything else
#                                  added or changed, or executable or a link, waits for a yes (held() below)
#   tools/sync-end4.sh mark [SHA]  record upstream/main (or SHA) as reviewed (tools/end4-reviewed; commit it)
# Commits use this repo's git identity (git config user.name / user.email).
set -euo pipefail
cd "$(dirname "$0")/.."
# No git hook runs from here: a picked tree can hold hooks (post-index-change and reference-transaction run during the
# cherry-pick itself), and a core.hooksPath into the tree would read them. For every git call below, fetch included
NOHOOKS="git -c core.hooksPath=/dev/null"
n=${GIT_CONFIG_COUNT:-0}
export "GIT_CONFIG_KEY_$n=core.hooksPath" "GIT_CONFIG_VALUE_$n=/dev/null" GIT_CONFIG_COUNT=$((n + 1))

MARK=tools/end4-reviewed
git remote get-url upstream >/dev/null 2>&1 || git remote add --no-tags upstream https://github.com/end-4/dots-hyprland.git # a fresh clone
git fetch -q --no-tags upstream # its tags stay out of this clone, and out of a push of tags
reviewed=$(cat "$MARK" 2>/dev/null || git merge-base HEAD upstream/main)

# end-4 code removed here on purpose (2026-11: Arch-family only, no other distros or end-4's file installer; Nexus
# instead of end-4's Settings app).
# A pick keeps these removed even when an upstream commit adds a new file under them.
removed_prefixes=(
  sdata/dist-fedora/ sdata/dist-gentoo/ sdata/dist-nix/ sdata/uv/shell.nix
  sdata/subcmd-exp-merge/ sdata/subcmd-exp-update/ sdata/subcmd-uninstall/
  sdata/subcmd-install/0.greeting.sh sdata/subcmd-install/3.files
  sdata/dist-arch/illogical-impulse-quickshell-git/ sdata/dist-arch/outdate-detect-mode
  sdata/dist-arch/previous_dependencies.conf sdata/dist-arch/uninstall-deps.sh
  dots-extra/via-nix/ dots-extra/fedora/
  # end-4's Settings and Welcome apps: Nexus is the one settings app (README, docs/install.md)
  dots/.config/quickshell/ii/settings.qml dots/.config/quickshell/ii/welcome.qml
  dots/.config/quickshell/ii/modules/settings/
)
is_removed() {
  local p
  for p in "${removed_prefixes[@]}"; do [[ $1 == "$p"* ]] && return 0; done
  return 1
}

review() {
  local n
  n=$(git rev-list --count "$reviewed..upstream/main")
  echo "end-4 commits since the last review ($(git log -1 --format='%h %cs' "$reviewed")): $n"
  git log --reverse --format='%H %h %cs %s' "$reviewed..upstream/main" | while read -r full short date subject; do
    local kept=() gone=() new=()
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      # removed: under the list above, or upstream had it at the last review and it's gone here (removed earlier)
      if [[ -e "$f" ]]; then kept+=("$f")
      elif is_removed "$f" || git cat-file -e "$reviewed:$f" 2>/dev/null; then gone+=("$f")
      else new+=("$f"); fi
    done < <(git diff-tree --no-commit-id --name-only -r "$full")
    echo
    echo "$short $date $subject"
    # if, not &&: a false test as the loop's last command would fail the pipeline and end the script (set -e, pipefail)
    if ((${#kept[@]})); then printf '    kept:         %s\n' "${kept[@]}"; fi
    if ((${#gone[@]})); then printf '    removed:      %s\n' "${gone[@]}"; fi
    if ((${#new[@]})); then printf '    new upstream: %s\n' "${new[@]}"; fi
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

# held: what of the staged pick waits for a yes, one quoted path a line. caelestia4: an allowlist, not a denylist (a
# path no rule named, .claude/ or .gitmodules or system/ say, was committed and signed with no prompt): only a plain,
# non-executable file under dots/ or dots-extra/ (end-4's dots, installed into the user's home) goes in without asking.
# Everything else is held: the root and its dotfiles (.claude/ settings and hooks run in the maintainer's next Claude
# Code session, .gitmodules URLs are fetched by CI, .gitattributes filters run on checkout), .github/ tools/ packaging/
# sdata/ (CI, the tools, the packages, the installer: run with secrets or as root), system/ (installed as root),
# third_party/, licenses/; under the dots too, anything .git* or .claude* and dots-extra/greetd/ (installed as root for
# the greeter); and anything executable, a link or a submodule, wherever it is. No sdata/ file is let through: end-4's
# installer steps run as root. A file only deleted isn't held. An unmerged file is judged by upstream's side of it
held() {
  local st nm f
  while IFS= read -r -d '' st && IFS= read -r -d '' f; do
    read -r _ nm _ _ st <<<"${st#:}"
    [[ $st == D* ]] && continue
    if [[ $st == U* ]]; then
      nm=$(git ls-files -u -z -- ":(literal)$f" | tr '\0' '\n' | awk -F'[ \t]' '$3 == 3 { print $1; exit }')
    fi
    plain_dots "$f" "$nm" || printf '    %q\n' "$f"
  done < <(git diff --cached --raw --no-renames -z)
  return 0
}
# plain_dots PATH MODE: the one kind of change committed without a yes
plain_dots() {
  [[ $2 == 100644 ]] || return 1
  case $1 in dots/* | dots-extra/*) ;; *) return 1 ;; esac
  case /$1/ in */.git*/* | */.claude*/* | /dots-extra/greetd/*) return 1 ;; esac
  return 0
}
HELD_WHAT="adds or changes files outside dots/ and dots-extra/ (or .git*, .claude* or dots-extra/greetd/ in them), or executables, links or submodules"

pick() {
  git diff --quiet && git diff --cached --quiet || { echo "working tree not clean" >&2; exit 1; }
  local sha f msg list
  msg=$(git rev-parse --path-format=absolute --git-path caelestia4-pick-msg)
  for sha in "$@"; do
    sha=$(git rev-parse --verify "$sha^{commit}")
    # Applied without committing, then committed as this repo's identity (signed) with the source named in the message
    printf '%s\n\nPicked from end-4/dots-hyprland@%s (%s).\n' "$(git log -1 --format=%s "$sha")" "$sha" \
      "$(git log -1 --format='%an, %cs' "$sha")" > "$msg"
    if ! git cherry-pick --no-commit "$sha"; then
      # A change to a file removed here (modify/delete): keep it removed
      while IFS= read -r f; do
        if ! git cat-file -e "HEAD:$f" 2>/dev/null; then git rm -q -- "$f" && echo "kept removed: $f"; fi
      done < <(git diff --name-only --diff-filter=U)
      if [[ -n "$(git diff --name-only --diff-filter=U)" ]]; then
        echo "${sha:0:9} has conflicts left to resolve:"
        git diff --name-only --diff-filter=U | sed 's/^/    /'
        list=$(held)
        if [[ -n $list ]]; then
          echo "and $HELD_WHAT; read them (git diff --cached, git diff) before committing:"
          echo "$list"
        fi
        echo "Then git add them, git cherry-pick --quit, and commit with: $NOHOOKS commit -S -F $msg"
        echo "(no hooks: the picked tree's own can't run), or undo it all with: $NOHOOKS cherry-pick --abort"
        exit 1
      fi
    fi
    # A new file under code removed here applies without a conflict: keep it out too
    while IFS= read -r f; do
      if is_removed "$f"; then git rm -q -f -- "$f" && echo "kept removed: $f"; fi
    done < <(git diff --cached --name-only --diff-filter=A)
    git cherry-pick --quit 2>/dev/null || true
    if git diff --cached --quiet; then
      echo "skipped ${sha:0:9}: nothing to apply (already here, or it only touches files removed here)"
      continue
    fi
    list=$(held)
    if [[ -n $list ]]; then
      echo "${sha:0:9} $HELD_WHAT:"
      echo "$list"
      local yes=
      if [[ -t 0 ]]; then read -rp "read them (git diff --cached); commit them with the rest? [y/N] " yes; fi
      if [[ $yes != [yY] ]]; then
        echo "not committed: the pick is staged for review (git diff --cached); the SHAs after it weren't picked."
        echo "Drop a file with git rm --cached, then commit with: $NOHOOKS commit -S -F $msg"
        echo "(no hooks: the picked tree's own can't run), or undo it all with: $NOHOOKS reset --hard HEAD"
        exit 1
      fi
    fi
    git commit -S -q -F "$msg"
    rm -f -- "$msg"
    echo "picked: $(git log -1 --format='%h %s')"
  done
}

mark() {
  # Resolved before the file is written, so a bad SHA leaves the last mark in place instead of an empty one
  local sha
  sha=$(git rev-parse --verify -q "${1:-upstream/main}^{commit}") || { echo "not a commit: ${1:-upstream/main}" >&2; exit 1; }
  echo "$sha" > "$MARK"
  echo "reviewed up to $(git log -1 --format='%h %cs %s' "$sha") ($MARK: commit it)"
}

cmd=${1:-review}
shift || true
case "$cmd" in
  review) review ;;
  pick) (($#)) || { echo "usage: $0 pick SHA..." >&2; exit 1; }; pick "$@" ;;
  mark) mark "$@" ;;
  *) sed -n '2,11p' "$0" >&2; exit 1 ;;
esac

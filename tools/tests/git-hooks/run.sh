#!/usr/bin/env bash
# Tests for tools/git-hooks: pre-push refuses a push holding a denylisted text however its diacritics are encoded (NFC
# or NFD) and on CRLF lines, and tools/git-hooks/install.sh installs it as a copy that a checked-out branch can't
# replace or add to. Throwaway repos, a bare remote and a fake XDG_CONFIG_HOME with synthetic patterns only, all in a
# temporary directory; the real HOME, git config and denylist aren't read.
# Usage: tools/tests/git-hooks/run.sh
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME=$tmp/home XDG_CONFIG_HOME=$tmp/config GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
  GIT_CEILING_DIRECTORIES=$tmp GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid \
  GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid
mkdir -p "$HOME" "$XDG_CONFIG_HOME/caelestia4"

fails=0
ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails + 1)); }

# The synthetic name, composed (NFC) and decomposed (NFD), built from code points so this file holds neither form
name='"Qq" + chr(0x1ea7) + "x Zz" + chr(0x1ecb) + "q"'
nfc=$(python3 -I -c "import unicodedata; print(unicodedata.normalize('NFC', $name))")
nfd=$(python3 -I -c "import unicodedata; print(unicodedata.normalize('NFD', $name))")
[[ $nfc != "$nfd" ]] || { echo "FAIL: the NFC and NFD forms are the same"; exit 1; }
printf '%s\n' "# synthetic test patterns" "$nfc" '^qq-anchored-marker$' > "$XDG_CONFIG_HOME/caelestia4/push-denylist"

# repo DIR: a clone of a fresh bare remote with one clean commit pushed (no hook yet)
repo() {
  git init -q --bare "$1.git"
  git init -q -b main "$1"
  git -C "$1" remote add origin "$1.git"
  echo clean > "$1/README"
  git -C "$1" add README && git -C "$1" commit -q -m init && git -C "$1" push -q origin main
}
# hook DIR FILE: commit FILE (already written) and run the hook on that push; prints its exit code
hook() {
  local d=$1 f=$2 sha old
  git -C "$d" add -- "$f" && git -C "$d" commit -q -m "add $f"
  sha=$(git -C "$d" rev-parse HEAD) old=$(git -C "$d" rev-parse origin/main)
  (cd "$d" && printf 'refs/heads/main %s refs/heads/main %s\n' "$sha" "$old" |
    "$root/tools/git-hooks/pre-push" origin "$d.git" >/dev/null 2>&1) && echo 0 || echo $?
}

# ---- pre-push: Unicode forms and CRLF ----
repo "$tmp/a"
printf 'line one\n%s\n' "$nfd" > "$tmp/a/nfd.txt"
[[ $(hook "$tmp/a" nfd.txt) == 1 ]] && ok "an NFD file is refused by an NFC pattern" || bad "NFD text got through"
git -C "$tmp/a" reset -q --hard origin/main
printf 'line one\n%s\n' "$nfc" > "$tmp/a/nfc.txt"
[[ $(hook "$tmp/a" nfc.txt) == 1 ]] && ok "an NFC file is refused" || bad "NFC text got through"
git -C "$tmp/a" reset -q --hard origin/main
printf 'line one\r\nqq-anchored-marker\r\nline three\r\n' > "$tmp/a/crlf.txt"
[[ $(hook "$tmp/a" crlf.txt) == 1 ]] && ok "an anchored pattern matches a CRLF line" || bad "a CRLF line got through"
git -C "$tmp/a" reset -q --hard origin/main
printf 'x\rqq-anchored-marker\ry\r' > "$tmp/a/cr.txt"
[[ $(hook "$tmp/a" cr.txt) == 1 ]] && ok "an anchored pattern matches a lone-CR line" || bad "a lone-CR line got through"
git -C "$tmp/a" reset -q --hard origin/main
printf 'nothing here\r\nqq-anchored-marker and more\n' > "$tmp/a/clean.txt"
[[ $(hook "$tmp/a" clean.txt) == 0 ]] && ok "a clean push passes" || bad "a clean push was refused"
# the denylist in NFD, the file in NFC
git -C "$tmp/a" reset -q --hard origin/main
printf '%s\n' "$nfd" > "$XDG_CONFIG_HOME/caelestia4/push-denylist"
printf '%s\n' "$nfc" > "$tmp/a/nfc2.txt"
[[ $(hook "$tmp/a" nfc2.txt) == 1 ]] && ok "an NFD pattern refuses an NFC file" || bad "NFD pattern missed NFC text"
printf '%s\n' "# synthetic test patterns" "$nfc" '^qq-anchored-marker$' > "$XDG_CONFIG_HOME/caelestia4/push-denylist"

# ---- install.sh: a copy in .git/hooks, never the tree ----
repo "$tmp/b"
mkdir -p "$tmp/b/tools/git-hooks"
cp "$root/tools/git-hooks/pre-push" "$root/tools/git-hooks/install.sh" "$tmp/b/tools/git-hooks/"
git -C "$tmp/b" add tools && git -C "$tmp/b" commit -q -m hooks && git -C "$tmp/b" push -q origin main
git -C "$tmp/b" config core.hooksPath tools/git-hooks # as the docs once said
"$tmp/b/tools/git-hooks/install.sh" >/dev/null
if git -C "$tmp/b" config --get core.hooksPath >/dev/null; then bad "install.sh left core.hooksPath set"
else ok "install.sh unsets a core.hooksPath in the tree"; fi
installed=$(git -C "$tmp/b" rev-parse --path-format=absolute --git-common-dir)/hooks/pre-push
cmp -s "$installed" "$root/tools/git-hooks/pre-push" && [[ -x $installed ]] && ok "pre-push is copied to .git/hooks" \
  || bad "pre-push isn't installed in .git/hooks"
# A branch that adds a post-checkout hook and turns pre-push off: neither may run
git -C "$tmp/b" switch -q -c evil
printf '#!/bin/sh\ntouch "%s"\n' "$tmp/ran-post-checkout" > "$tmp/b/tools/git-hooks/post-checkout"
printf '#!/bin/sh\ntouch "%s"\nexit 0\n' "$tmp/ran-evil-pre-push" > "$tmp/b/tools/git-hooks/pre-push"
chmod +x "$tmp/b/tools/git-hooks/post-checkout" "$tmp/b/tools/git-hooks/pre-push"
git -C "$tmp/b" add tools && git -C "$tmp/b" commit -q -m evil
git -C "$tmp/b" switch -q main && git -C "$tmp/b" switch -q evil
[[ ! -e $tmp/ran-post-checkout ]] && ok "a checked-out branch's post-checkout doesn't run" \
  || bad "a branch's post-checkout ran"
printf '%s\n' "$nfd" > "$tmp/b/leak.txt"
git -C "$tmp/b" add leak.txt && git -C "$tmp/b" commit -q -m leak
if git -C "$tmp/b" push -q origin evil >/dev/null 2>&1; then bad "a push with denylisted text got through"
else ok "the installed pre-push refuses it, whatever the branch's pre-push says"; fi
[[ ! -e $tmp/ran-evil-pre-push ]] && ok "the branch's pre-push doesn't run" || bad "the branch's pre-push ran"
# Run again on an unchanged copy: nothing kept aside
git -C "$tmp/b" switch -q main
"$tmp/b/tools/git-hooks/install.sh" >/dev/null
olds() { compgen -G "$installed.old*" | wc -l; }
[[ $(olds) == 0 ]] && ok "reinstalling the same hook keeps no .old" || bad "an unneeded .old was made"
# A different hook there: kept aside under a name of its own, never over an earlier one
echo '#!/bin/sh' > "$installed"
"$tmp/b/tools/git-hooks/install.sh" >/dev/null
[[ $(olds) == 1 ]] && cmp -s "$installed" "$root/tools/git-hooks/pre-push" && ok "a changed hook is kept as .old.<time>" \
  || bad "a changed hook wasn't kept aside"
kept=$(compgen -G "$installed.old*")
echo '#!/bin/sh' > "$installed"
cp "$kept" "$tmp/kept-before"
# (installed with a second .old, or refused when that name, the same second's, is taken)
if "$tmp/b/tools/git-hooks/install.sh" >/dev/null 2>&1; then
  [[ $(olds) == 2 ]] && ok "a second change is kept too" || bad "a second change wasn't kept"
else ok "a second change in the same second is refused"; fi
cmp -s "$kept" "$tmp/kept-before" && ok "an earlier .old isn't written over" || bad "an earlier .old was written over"
rm -f "$installed".old*
"$tmp/b/tools/git-hooks/install.sh" >/dev/null 2>&1 || true
# core.hooksPath into the tree from the global config: not touched there, and no advice to copy a hook into the tree
printf '[core]\n\thooksPath = %s\n' "$tmp/b/tools/git-hooks" > "$tmp/global"
if out=$(GIT_CONFIG_GLOBAL=$tmp/global "$tmp/b/tools/git-hooks/install.sh" 2>&1); then
  bad "install.sh went on under a global core.hooksPath into the tree"
elif grep -q "Unset it in that file" <<<"$out" && ! grep -qi "copy tools/git-hooks" <<<"$out"; then
  ok "a global core.hooksPath into the tree: told to unset it, not to copy into the tree"
else bad "the global core.hooksPath advice: $out"; fi
grep -qF "$tmp/b/tools/git-hooks" "$tmp/global" || bad "install.sh changed the global config"
# .git/hooks itself a link into the tree: refused
mv "$(dirname "$installed")" "$tmp/hooks-aside"
ln -s "$tmp/b/tools/git-hooks" "$(dirname "$installed")"
if "$tmp/b/tools/git-hooks/install.sh" >/dev/null 2>&1; then bad "install.sh wrote through a hooks link into the tree"
else ok "install.sh refuses a hooks folder that is a link into the tree"; fi
cmp -s "$tmp/b/tools/git-hooks/pre-push" "$root/tools/git-hooks/pre-push" || bad "the tree's pre-push was changed"
rm "$(dirname "$installed")" && mv "$tmp/hooks-aside" "$(dirname "$installed")"
# core.hooksPath at the clone's own hooks folder: nothing to undo
git -C "$tmp/b" config core.hooksPath .git/hooks
"$tmp/b/tools/git-hooks/install.sh" >/dev/null 2>&1 && ok "core.hooksPath = .git/hooks is fine" \
  || bad "install.sh refused core.hooksPath = .git/hooks"
git -C "$tmp/b" config --unset core.hooksPath
# From a linked worktree, with core.hooksPath at the main tree's folder (absolute): unset too, same hooks folder
git -C "$tmp/b" worktree add -q "$tmp/b-wt" -b wt
git -C "$tmp/b" config core.hooksPath "$tmp/b/tools/git-hooks"
if "$tmp/b-wt/tools/git-hooks/install.sh" >/dev/null && ! git -C "$tmp/b" config --get core.hooksPath >/dev/null \
  && cmp -s "$installed" "$root/tools/git-hooks/pre-push"; then ok "install.sh from a worktree"
else bad "install.sh from a worktree"; fi
# A hooks folder outside every tree is someone's own choice: left alone, and said
git -C "$tmp/b" config core.hooksPath "$tmp/elsewhere"
if "$tmp/b/tools/git-hooks/install.sh" >/dev/null 2>&1; then bad "install.sh ignored a core.hooksPath it can't use"
else ok "install.sh stops on a core.hooksPath outside the tree"; fi
[[ $(git -C "$tmp/b" config --get core.hooksPath) == "$tmp/elsewhere" ]] \
  || bad "install.sh changed an outside hooksPath"
git -C "$tmp/b" config --unset core.hooksPath

# ---- the repo itself ----
hooks=$(git -C "$root" ls-files tools/git-hooks)
[[ $hooks == $'tools/git-hooks/install.sh\ntools/git-hooks/pre-push' ]] \
  && ok "tools/git-hooks holds only pre-push and install.sh" \
  || bad "tools/git-hooks holds more than pre-push and install.sh: $hooks"
if git -C "$root" grep -nE 'hooksPath[ =]+"?(\./)?tools/' -- '*.md' >/dev/null; then
  bad "the docs point core.hooksPath into the tree"
else ok "no doc points core.hooksPath into the tree"; fi

((fails == 0)) || { echo "git-hooks tests: $fails FAILED"; exit 1; }
echo "git-hooks tests: OK"

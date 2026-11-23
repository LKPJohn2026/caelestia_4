#!/usr/bin/env bash
# Tests for tools/sync-end4.sh pick: a commit touching only the dots is picked and signed; one that adds or changes
# anything outside dots/ and dots-extra/ (.github/, tools/, sdata/, .claude/, system/, .gitmodules, root files...),
# or anything executable or a link (a new file, a mode or type
# change, or new content), is left staged and not committed without a yes, and so listed when it conflicts too; no hook
# from the tree runs, during the cherry-pick either (post-index-change, reference-transaction). A fake upstream and fork
# in a temporary directory, a stub gpg and gh, no network.
# Usage: tools/tests/sync-end4/run.sh
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME=$tmp/home XDG_CONFIG_HOME=$tmp/home/.config GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
  GIT_CEILING_DIRECTORIES=$tmp GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid \
  GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid
mkdir -p "$HOME" "$tmp/bin"

fails=0
ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails + 1)); }

# gpg: a signature git accepts without a key; gh: never called for pick, and must not reach the network if it is
printf '%s\n' '#!/bin/sh' 'cat >/dev/null' 'printf "\n[GNUPG:] SIG_CREATED D 1 8 00 0 X\n" >&2' \
  'printf -- "-----BEGIN PGP SIGNATURE-----\n\nstub\n-----END PGP SIGNATURE-----\n"' > "$tmp/bin/gpg"
printf '%s\n' '#!/bin/sh' 'exit 1' > "$tmp/bin/gh"
chmod +x "$tmp/bin/gpg" "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH"

up=$tmp/upstream fork=$tmp/fork
# this test's own git calls in the fork run no hooks either
g() { git -C "$fork" -c core.hooksPath=/dev/null "$@"; }
# hook DIR NAME...: hooks that leave a mark in $tmp/ran
hook() {
  local d=$1 h
  shift
  for h; do printf '#!/bin/sh\necho %s >> "%s"\n' "$h" "$tmp/ran" > "$d/$h" && chmod +x "$d/$h"; done
}
ran() { [[ ! -e $tmp/ran ]] && ok "$1" || { bad "$1: $(sort -u "$tmp/ran" | tr '\n' ' ')"; rm -f "$tmp/ran"; }; }

git init -q -b main "$up"
mkdir -p "$up/dots" "$up/tools"
echo one > "$up/dots/x" && echo why > "$up/dots/y" && echo zed > "$up/dots/z" && echo ok > "$up/tools/existing.sh"
printf '#!/bin/sh\necho run\n' > "$up/dots/run.sh" && chmod +x "$up/dots/run.sh"
git -C "$up" add . && git -C "$up" commit -q -m base
git clone -q "$up" "$fork"
g remote rename origin upstream
g config gpg.program "$tmp/bin/gpg"
mkdir -p "$fork/tools/git-hooks"
cp "$root/tools/sync-end4.sh" "$fork/tools/"
# Hooks already in the tree with core.hooksPath at them (the old setup): nothing the script runs may run them
hook "$fork/tools/git-hooks" pre-commit commit-msg post-commit post-index-change reference-transaction post-checkout
g add tools && g commit -q -m fork
g config core.hooksPath tools/git-hooks

# 1. only the dots
echo two > "$up/dots/x"
git -C "$up" commit -q -am "fix(hypr): dots only"
c1=$(git -C "$up" rev-parse HEAD)
# 2. the dots plus CI, a tool, the installer's data, an executable installer, hooks
echo three > "$up/dots/x"
mkdir -p "$up/.github/workflows" "$up/tools/git-hooks" "$up/sdata"
echo 'on: pull_request_target' > "$up/.github/workflows/new.yml"
echo 'echo hi' > "$up/tools/foo.sh"
echo 'x=1' > "$up/sdata/new.conf"
printf '#!/bin/sh\necho installer\n' > "$up/install.sh" && chmod +x "$up/install.sh"
hook "$up/tools/git-hooks" pre-commit commit-msg post-commit post-index-change reference-transaction
git -C "$up" add . && git -C "$up" commit -q -m "fix(hypr): innocuous"
c2=$(git -C "$up" rev-parse HEAD)
git -C "$up" rm -q -r tools/git-hooks .github install.sh tools/foo.sh sdata && git -C "$up" commit -q -m "drop them"
# 3. an existing dots file made executable
chmod +x "$up/dots/y"
git -C "$up" commit -q -am "chore: mode"
c3=$(git -C "$up" rev-parse HEAD)
# 4. an existing file replaced by a link (a type change: T, not M)
git -C "$up" rm -q dots/z && ln -s /nonexistent/target "$up/dots/z" && git -C "$up" add dots/z
git -C "$up" commit -q -m "chore: link"
c4=$(git -C "$up" rev-parse HEAD)
# 5. new content in an existing tool; 6. in an existing executable outside those folders
echo 'echo appended' >> "$up/tools/existing.sh" && git -C "$up" commit -q -am "chore: tool"
c5=$(git -C "$up" rev-parse HEAD)
echo 'echo appended' >> "$up/dots/run.sh" && git -C "$up" commit -q -am "chore: script"
c6=$(git -C "$up" rev-parse HEAD)
# 7. a conflict in the dots, with a new workflow beside it
echo four > "$up/dots/x"
mkdir -p "$up/.github/workflows" && echo 'on: pull_request_target' > "$up/.github/workflows/conflict.yml"
git -C "$up" add . && git -C "$up" commit -q -m "fix: conflicting"
c7=$(git -C "$up" rev-parse HEAD)
# 8. paths no denylist named: an allowlist holds everything but plain files in the dots (and a plain dots-extra file
# goes in with them)
mkdir -p "$up/.claude" "$up/system/udev" "$up/third_party/x" "$up/licenses" "$up/dots/.claude" \
  "$up/dots-extra/greetd" "$up/dots-extra/other"
echo '{"hooks":{}}' > "$up/.claude/settings.json"
echo 'RUN+="/bin/sh -c id"' > "$up/system/udev/99.rules"
printf '[submodule "s"]\n\turl = https://example.invalid/s\n' > "$up/.gitmodules"
echo '* filter=x' > "$up/.gitattributes"
echo 'Item {}' > "$up/third_party/x/a.qml"
echo text > "$up/licenses/NEW" && echo note > "$up/NOTES" && echo x > "$up/.envrc"
echo '{}' > "$up/dots/.claude/settings.json" && echo '* filter=x' > "$up/dots/.gitattributes"
echo auth > "$up/dots-extra/greetd/pam-greetd" && echo fine > "$up/dots-extra/other/plain.conf"
git -C "$up" add . && git -C "$up" commit -q -m "chore: misc"
c8=$(git -C "$up" rev-parse HEAD)

head0=$(g rev-parse HEAD)
if out=$("$fork/tools/sync-end4.sh" pick "$c1" </dev/null 2>&1) && [[ $(g show HEAD:dots/x) == two ]]; then
  ok "a dots-only commit is picked"
else bad "a dots-only commit wasn't picked: $out"; fi
g cat-file commit HEAD | grep -q '^gpgsig ' && ok "the pick is signed" || bad "the pick isn't signed"
g log -1 --format=%B | grep -q "Picked from end-4/dots-hyprland@$c1" && ok "the message names the source" \
  || bad "the message doesn't name the source"
ran "no hook in the tree ran on the fetch, the cherry-pick or the commit"
[[ $(g rev-parse HEAD) != "$head0" ]] || bad "HEAD didn't move"
# the next pick brings hooks of its own to the same folder (core.hooksPath still at it)
g rm -q -r tools/git-hooks && g commit -q -m "no hooks in the tree"

head1=$(g rev-parse HEAD)
if out=$("$fork/tools/sync-end4.sh" pick "$c2" </dev/null 2>&1); then bad "a pick adding CI and tools succeeded"
else ok "a pick adding CI, tools, sdata and executables stops"; fi
[[ $(g rev-parse HEAD) == "$head1" ]] && ok "it isn't committed" || bad "it was committed"
for f in .github/workflows/new.yml tools/foo.sh sdata/new.conf install.sh tools/git-hooks/post-commit; do
  grep -qF -- "$f" <<<"$out" || bad "$f isn't listed"
done
grep -qF -- "dots/x" <<<"$out" && bad "dots/x is listed as held" || ok "each held file is listed, and only those"
g diff --cached --quiet && bad "nothing is left staged for review" || ok "the pick is left staged"
ran "the picked hooks didn't run (post-index-change and reference-transaction neither)"
msg=$(g rev-parse --path-format=absolute --git-path caelestia4-pick-msg)
grep -qF -- "git -c core.hooksPath=/dev/null commit -S -F $msg" <<<"$out" && ok "the commit it prints runs no hooks" \
  || bad "the printed commit would run the tree's hooks: $out"
g reset -q --hard HEAD

# expect_held SHA FILE WHAT: the pick stops, lists FILE, and leaves HEAD
expect_held() {
  local h out
  h=$(g rev-parse HEAD)
  if out=$("$fork/tools/sync-end4.sh" pick "$1" </dev/null 2>&1); then bad "$3 was committed"
  elif grep -qF -- "$2" <<<"$out" && [[ $(g rev-parse HEAD) == "$h" ]]; then ok "$3 is held"
  else bad "$3: $2 isn't listed: $out"; fi
  g reset -q --hard "$h"
  ran "no hook ran for $3"
}
expect_held "$c3" dots/y "a file made executable"
expect_held "$c4" dots/z "a file replaced by a link"
expect_held "$c5" tools/existing.sh "new content in an existing tool"
expect_held "$c6" dots/run.sh "new content in an existing executable"

h=$(g rev-parse HEAD)
if out=$("$fork/tools/sync-end4.sh" pick "$c7" </dev/null 2>&1); then bad "a conflicting pick succeeded"
else ok "a conflicting pick stops"; fi
grep -qF -- dots/x <<<"$out" && ok "the conflict is named" || bad "the conflict isn't named: $out"
grep -qF -- .github/workflows/conflict.yml <<<"$out" && ok "a new workflow beside a conflict is listed" \
  || bad "a new workflow beside a conflict isn't listed: $out"
grep -qF -- "git -c core.hooksPath=/dev/null commit -S -F" <<<"$out" && ok "the conflict's commit runs no hooks" \
  || bad "the conflict's commit would run the tree's hooks: $out"
[[ $(g rev-parse HEAD) == "$h" ]] || bad "a conflicting pick moved HEAD"
ran "no hook ran on the conflicting pick"
g cherry-pick --abort 2>/dev/null || g reset -q --hard "$h"

h=$(g rev-parse HEAD)
if out=$("$fork/tools/sync-end4.sh" pick "$c8" </dev/null 2>&1); then bad "a pick adding .claude/, system/ and the like was committed"
else ok "a pick adding .claude/, system/, .gitmodules and the like stops"; fi
for f in .claude/settings.json system/udev/99.rules .gitmodules .gitattributes third_party/x/a.qml licenses/NEW NOTES \
  .envrc dots/.claude/settings.json dots/.gitattributes dots-extra/greetd/pam-greetd; do
  grep -qF -- "    $f" <<<"$out" && ok "$f is held" || bad "$f isn't held: $out"
done
grep -qF -- dots-extra/other/plain.conf <<<"$out" && bad "a plain dots-extra file is held" \
  || ok "a plain dots-extra file isn't held"
[[ $(g rev-parse HEAD) == "$h" ]] || bad "it moved HEAD"
g reset -q --hard "$h"
ran "no hook ran for the allowlist pick"

((fails == 0)) || { echo "sync-end4 tests: $fails FAILED"; exit 1; }
echo "sync-end4 tests: OK"

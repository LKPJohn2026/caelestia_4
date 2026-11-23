#!/usr/bin/env bash
# Tests for require_licence in tools/sync-upstreams.sh (taken out of the script and run alone): a repo counts as
# licensed only by a regular LICENSE/LICENCE/COPYING file or one in LICENSES/ with more than blanks in it, never by a
# link, an empty file or one of only blanks. Throwaway repos in a temporary directory, fetched by path; no network.
# Usage: tools/tests/licence-check/run.sh
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME=$tmp/home GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CEILING_DIRECTORIES=$tmp \
  GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid GIT_COMMITTER_NAME=Test \
  GIT_COMMITTER_EMAIL=test@example.invalid
mkdir -p "$HOME"
sed -n '/^require_licence() {$/,/^}$/p' "$root/tools/sync-upstreams.sh" > "$tmp/fn.sh"
grep -q '^require_licence() {$' "$tmp/fn.sh" || { echo "FAIL: require_licence not found"; exit 1; }

fails=0
ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails + 1)); }

git init -q "$tmp/vendor"
# upstream SETUP...: a repo made by running SETUP in it, with a README; prints its path
upstream() {
  local d
  d=$(mktemp -d "$tmp/up.XXXXXX")
  git init -q -b main "$d" && echo readme > "$d/README"
  (cd "$d" && eval "$1") && git -C "$d" add -A && git -C "$d" commit -q -m up && echo "$d"
}
# expect pass|fail DESCRIPTION SETUP
expect() {
  local d rc=0
  d=$(upstream "$3")
  (cd "$tmp/vendor" && source "$tmp/fn.sh" && require_licence "$d" main) >/dev/null 2>&1 || rc=$?
  if [[ $1 == pass && $rc == 0 || $1 == fail && $rc != 0 ]]; then ok "$2"; else bad "$2"; fi
}

expect pass "a LICENSE file" 'echo "GPL text" > LICENSE'
expect pass "COPYING.md" 'echo "GPL text" > COPYING.md'
expect pass "a file in LICENSES/" 'mkdir LICENSES && echo "GPL text" > LICENSES/GPL-3.0-only.txt'
expect fail "no licence" 'true'
expect fail "LICENSE is a link" 'echo "GPL text" > other && ln -s other LICENSE'
expect fail "LICENSE is a dangling link" 'ln -s /nonexistent LICENSE'
expect fail "LICENSE is empty" ': > LICENSE'
expect fail "LICENSE is only a newline" "printf '\\n' > LICENSE"
expect fail "LICENSE is only blanks" "printf ' \\t \\r\\n\\n  ' > LICENSE"
expect fail "LICENSES/ holds only a blank file" "mkdir LICENSES && printf '\\n\\n' > LICENSES/GPL-3.0-only.txt"
expect pass "a blank LICENSE beside a real COPYING" "printf '\\n' > LICENSE && echo 'GPL text' > COPYING"
expect pass "a one-word licence" 'echo MIT > LICENSE'
expect fail "LICENSES/ holds only an empty file" 'mkdir LICENSES && : > LICENSES/GPL-3.0-only.txt'
expect fail "LICENSES/ holds only a link" 'mkdir LICENSES && echo x > o && ln -s ../o LICENSES/GPL-3.0-only.txt'
expect fail "LICENSES is a link to a folder" 'mkdir real && echo "GPL text" > real/GPL && ln -s real LICENSES'
expect fail "a licence only deeper in the tree" 'mkdir sub && echo "GPL text" > sub/LICENSE'
rc=0
d=$(upstream 'true')
(cd "$tmp/vendor" && source "$tmp/fn.sh" && ALLOW_UNLICENSED=1 require_licence "$d" main) >/dev/null 2>&1 || rc=$?
((rc == 0)) && ok "ALLOW_UNLICENSED=1 still overrides" || bad "ALLOW_UNLICENSED=1 doesn't override"

((fails == 0)) || { echo "licence-check tests: $fails FAILED"; exit 1; }
echo "licence-check tests: OK"

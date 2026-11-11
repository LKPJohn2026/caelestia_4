#!/usr/bin/env bash
# The checks run on every push and pull request (.github/workflows/lint.yml), and the same ones to run before you open a
# pull request. Only files git tracks are checked, and nothing here runs the shell or touches the desktop.
#   1. tools/lint-caelestia.sh: the Caelestia family's own checks (singletons, unported imports, hyprlock variables)
#   2. Lua syntax of the Hyprland config (luac -p; the Lua config is Lua 5.4)
#   3. JSON files parse (translations, presets, settings)
#   4. Python files parse
#   5. shellcheck (warnings and errors) on this fork's own shell scripts; the ones from end-4 aren't checked
# Needs: bash, git, luac5.4 (or luac), jq, python3, shellcheck. Locally a missing tool is skipped with a note; in CI
# (CI=true) it fails.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2

fail=0
missing() {
  if [[ "${CI:-}" == true ]]; then echo "FAIL: $1 is not installed"; fail=1
  else echo "skip: $1 is not installed"; fi
}
tracked() { git ls-files -z -- "$@"; }

echo "== lint-caelestia"
tools/lint-caelestia.sh || fail=1

echo "== Lua syntax"
luac=$(command -v luac5.4 || command -v luac || true)
if [[ -z "$luac" ]]; then missing luac
else
  n=0
  while IFS= read -r -d '' f; do
    "$luac" -p -- "$f" || fail=1; n=$((n + 1))
  done < <(tracked 'dots/**/*.lua')
  echo "$n files"
fi

echo "== JSON"
if ! command -v jq >/dev/null; then missing jq
else
  n=0
  while IFS= read -r -d '' f; do
    jq empty -- "$f" >/dev/null 2>&1 || { echo "FAIL: $f is not valid JSON"; fail=1; }; n=$((n + 1))
  done < <(tracked '*.json' ':!:third_party/**')
  echo "$n files"
fi

echo "== Python syntax"
if ! command -v python3 >/dev/null; then missing python3
else
  tracked '*.py' ':!:third_party/**' | python3 -I -c '
import ast, sys
files = [f for f in sys.stdin.buffer.read().decode().split("\0") if f]
bad = 0
for f in files:
    try:
        ast.parse(open(f, "rb").read(), f)
    except SyntaxError as e:
        print(f"FAIL: {f}:{e.lineno}: {e.msg}"); bad = 1
print(f"{len(files)} files")
sys.exit(bad)' || fail=1
fi

echo "== shellcheck (this fork's scripts)"
if ! command -v shellcheck >/dev/null; then missing shellcheck
else
  mapfile -d '' scripts < <(tracked install.sh 'tools/*.sh' 'tools/tests/**/*.sh' 'dots/.config/quickshell/ii/scripts/caelestia4/*.sh' 'dots-extra/**/*.sh')
  shellcheck --severity=warning -- "${scripts[@]}" || fail=1
  echo "${#scripts[@]} files"
fi

[[ $fail -eq 0 ]] && echo "ci-lint: OK" || echo "ci-lint: FAILED"
exit $fail

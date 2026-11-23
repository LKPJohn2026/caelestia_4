#!/usr/bin/env bash
# The checks run on every push and pull request (.github/workflows/lint.yml), and the same ones to run before you open a
# pull request. Only files git tracks are checked, and nothing here runs the shell or touches the desktop.
#   1. tools/lint-caelestia.sh: the Caelestia family's own checks (singletons, unported imports, hyprlock variables)
#   2. Lua syntax of the Hyprland config (luac -p; the Lua config is Lua 5.4)
#   3. JSON files parse (translations, presets, settings)
#   4. Python files parse
#   5. shellcheck (warnings and errors) on this fork's own shell scripts; the ones from end-4 aren't checked
#   6. Nexus coverage: every end-4 and Caelestia option has a Nexus row or an ignored.json reason, and
#      registry/E4Defaults.js matches modules/common/Config.qml, and every setting kept in both shell.json and
#      config.json is synced from its Caelestia key (tools/nexus-coverage.py; reads files only)
#   7. no monitor data: connector names, monitor descriptions, modes and scales are read at run time, never written
#      in (tools/lint-monitors.sh; generic patterns, Caelestia's vendored shell included, see that file)
#   8. a warning (not a failure) when core.hooksPath points into a working tree (tools/git-hooks/install.sh fixes it)
#   9. every offline test in tools/tests/<name>/ (run.sh or run.py; throwaway repos, fake HOMEs and stub commands,
#      never the real system). Only listed: a folder with a QML file, which needs this fork's Quickshell and is run by
#      tools/ci-qml.sh (.github/workflows/qml.yml), and one with a MANUAL file, which needs a desktop
# Needs: bash, git, luac5.4 (or luac), jq, python3, shellcheck; the tests also node, visudo (sudo) and PyGObject.
# Locally a missing tool is skipped with a note; in CI (CI=true) it fails.
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

echo "== Nexus coverage"
if ! command -v python3 >/dev/null; then missing python3
else
  python3 -I tools/nexus-coverage.py --strict --check-defaults --check-mirrors || fail=1
fi

echo "== Monitor data"
tools/lint-monitors.sh || fail=1

# caelestia4: a clone set up under the old docs (core.hooksPath=tools/git-hooks) runs whatever hooks the checked-out
# commit holds, in every worktree of the clone. Only a warning (it's this clone's setting, not the change under test):
# tools/git-hooks/install.sh unsets it and installs a copy in .git/hooks
echo "== git hooks"
if hp=$(git config --type=path --get core.hooksPath 2>/dev/null); then
  [[ $hp == /* ]] || hp="$(git rev-parse --show-toplevel)/$hp"
  hp=$(realpath -m -- "$hp")
  intree=
  while IFS= read -r w; do
    w=$(realpath -m -- "${w#worktree }")
    [[ $hp == "$w" || $hp == "$w/"* ]] && intree=$w
  done < <(git worktree list --porcelain | grep '^worktree ')
  if [[ -n $intree ]]; then
    echo "WARN: core.hooksPath ($(git config --show-origin --get core.hooksPath | cut -f1)) is in a working tree, so"
    echo "      git runs the hooks the checked-out commit holds: run tools/git-hooks/install.sh"
  else echo "core.hooksPath is outside the working trees"; fi
else echo "core.hooksPath unset (.git/hooks)"; fi

# Every offline test: tools/tests/<name>/run.sh or run.py, run from the repo root, exit 0 when it passes. Skipped
# here, each with a file in its folder giving the reason: QML (it needs this fork's Quickshell build; tools/ci-qml.sh
# runs it, and CI's QML job) and MANUAL (it needs a desktop or a display). On success only the test's last line is
# shown, on a failure all of its output
echo "== tests (tools/tests)"
for dir in tools/tests/*/; do
  name=$(basename "$dir")
  [[ -e $dir/QML ]] && { echo "qml: $name (tools/ci-qml.sh)"; continue; }
  [[ -e $dir/MANUAL ]] && { echo "manual: $name"; continue; }
  if [[ -x $dir/run.sh ]]; then cmd=("$dir/run.sh")
  elif [[ -f $dir/run.py ]]; then
    command -v python3 >/dev/null || { missing python3; continue; }
    cmd=(python3 -I "$dir/run.py")
  else continue; fi
  if out=$("${cmd[@]}" 2>&1); then echo "${out##*$'\n'}"
  else printf '%s\n' "$out" | grep -v -e '^ok: ' -e '^  ok'; echo "FAIL: tools/tests/$name"; fail=1; fi
done

[[ $fail -eq 0 ]] && echo "ci-lint: OK" || echo "ci-lint: FAILED"
exit $fail

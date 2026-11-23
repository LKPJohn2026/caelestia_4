#!/usr/bin/env bash
# The QML checks: the same run locally and in CI (.github/workflows/qml.yml builds what they need, then runs this as a
# normal user). Run it before a pull request that changes the shell, after tools/ci-lint.sh.
#   1. every tools/tests/<name>/ with a file named QML: its shell.qml under this fork's Quickshell, offscreen (no
#      compositor at all), with an empty environment, a fake HOME and XDG dirs and a private D-Bus; it passes when
#      the output has a "SMOKE OK" line (plugin-smoke: the Caelestia plugin's modules load)
#   2. tools/compile-check.sh [Family ...] (default CaelestiaFamily): the families compiled, never instantiated, in a
#      private headless sway
# Never touches the running desktop: without sway, compile-check would connect to $WAYLAND_DISPLAY, so this refuses to
# run it (exit 2), and it gets no WAYLAND_DISPLAY, DISPLAY or HYPRLAND_INSTANCE_SIGNATURE either way.
# Needs: this fork's Quickshell (qs; packaging/caelestia4-quickshell), the Caelestia plugin in ~/.local/lib/qt6/qml
# (tools/build-caelestia-plugin.sh), M3Shapes, sway, dbus-run-session, rsync. A missing one is a failure, locally too.
# Exit: 0 passed, 1 a check failed, 2 a check couldn't run.
# Usage: tools/ci-qml.sh [Family ...]
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2

[[ $(id -u) -ne 0 ]] || { echo "ci-qml: run it as a normal user, not root (sway and the shell refuse or misbehave)"; exit 2; }
need=0
for t in qs dbus-run-session rsync timeout; do
  command -v "$t" >/dev/null || { echo "FAIL: $t is not installed"; need=1; }
done
[[ $need -eq 0 ]] || exit 2
if ! qs --version 2>/dev/null | grep -q 'caelestia4-quickshell'; then
  echo "FAIL: qs is not this fork's Quickshell (packaging/caelestia4-quickshell): $(qs --version 2>&1 | head -1)"; exit 2
fi
qml_dir="$HOME/.local/lib/qt6/qml"
[[ -e $qml_dir/Caelestia/qmldir ]] ||
  { echo "FAIL: no Caelestia plugin in $qml_dir (build it: tools/build-caelestia-plugin.sh)"; exit 2; }

fail=0 cant=0
T=$(mktemp -d "${TMPDIR:-/tmp}/c4-ci-qml.XXXXXX")
trap 'rm -rf -- "$T"' EXIT

echo "== QML tests (tools/tests/*/QML)"
for dir in tools/tests/*/; do
  [[ -e $dir/QML ]] || continue
  name=$(basename "$dir")
  home="$T/$name/home"
  mkdir -p "$home"/{.config,.local/state,.cache,.local/share} "$T/$name/run"; chmod 700 "$T/$name/run"
  # QS_DISABLE_CRASH_HANDLER: its reporter would be a window; a crash shows up as the status below instead
  out=$(env -i PATH="$PATH" LANG=C.UTF-8 HOME="$home" XDG_CONFIG_HOME="$home/.config" XDG_STATE_HOME="$home/.local/state" \
          XDG_CACHE_HOME="$home/.cache" XDG_DATA_HOME="$home/.local/share" XDG_RUNTIME_DIR="$T/$name/run" \
          QT_QPA_PLATFORM=offscreen QML_IMPORT_PATH="$qml_dir" QS_DISABLE_CRASH_HANDLER=1 \
          dbus-run-session -- timeout 25 qs -p "$PWD/$dir" --no-color 2>&1); status=$?
  if grep -q 'SMOKE OK' <<<"$out"; then
    echo "qml: $name OK"
  else
    echo "FAIL: tools/tests/$name (qs exit $status, no SMOKE OK line)"
    grep -E 'ERROR|WARN|caused by|is not installed|not a type|SMOKE' <<<"$out" | tail -15
    fail=1
  fi
done

echo "== compile-check"
if ! command -v sway >/dev/null; then
  echo "FAIL: sway is not installed; compile-check would connect to the running session instead, so it isn't run"
  cant=1
else
  env -u WAYLAND_DISPLAY -u DISPLAY -u HYPRLAND_INSTANCE_SIGNATURE -u SWAYSOCK tools/compile-check.sh "$@"; rc=$?
  case $rc in 0) ;; 1) fail=1 ;; *) cant=1 ;; esac
fi

if [[ $fail -ne 0 ]]; then echo "ci-qml: FAILED"; exit 1
elif [[ $cant -ne 0 ]]; then echo "ci-qml: INCOMPLETE (a check couldn't run)"; exit 2
fi
echo "ci-qml: OK"

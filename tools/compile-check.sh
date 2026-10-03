#!/usr/bin/env bash
# Compile-check panel families WITHOUT running them on the real desktop.
# A throwaway copy of the ii tree gets a shell.qml that only declares `Component { <Family> {} }`
# (never instantiated): QML resolves/compiles the whole type tree (catches "Type X unavailable",
# "non-existent property", bad imports) but creates no services.
# Isolation: fake HOME/XDG dirs, private D-Bus session, and a private HEADLESS sway compositor
# (no screen, no input devices, socket inside the sandbox). Quickshell's PanelWindow needs layer-shell,
# so plain QT_QPA_PLATFORM=offscreen can't be used.
# Requires: sway (only as this invisible test compositor), dbus-run-session.
# Usage: tools/compile-check.sh [Family ...]   (default: CaelestiaFamily IllogicalImpulseFamily)
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
command -v sway >/dev/null || { echo "compile-check: needs sway (sudo pacman -S --needed sway)"; exit 2; }
fams=("$@"); [[ $# -eq 0 ]] && fams=(CaelestiaFamily IllogicalImpulseFamily)
T=$(mktemp -d "${TMPDIR:-/tmp}/c4-compile.XXXXXX"); trap 'kill "${SWAY_PID:-}" 2>/dev/null; rm -rf "$T"' EXIT
rsync -a --exclude '.git' dots/.config/quickshell/ii/ "$T/ii/"
mkdir -p "$T/home"/{.config,.local/state,.cache,.local/share} "$T/run"; chmod 700 "$T/run"
: > "$T/sway.conf"
export -n WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE
base_env=(env -i PATH="$PATH" HOME="$T/home" XDG_CONFIG_HOME="$T/home/.config" XDG_STATE_HOME="$T/home/.local/state"
  XDG_CACHE_HOME="$T/home/.cache" XDG_DATA_HOME="$T/home/.local/share" XDG_RUNTIME_DIR="$T/run")
"${base_env[@]}" WLR_BACKENDS=headless WLR_HEADLESS_OUTPUTS=1 WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman \
  sway -c "$T/sway.conf" >"$T/sway.log" 2>&1 &
SWAY_PID=$!
for _ in $(seq 1 50); do ls "$T/run"/wayland-* >/dev/null 2>&1 && break; sleep 0.1; done
WL=$(basename "$(ls "$T/run"/wayland-[0-9] 2>/dev/null | head -1)")
[[ -n "$WL" ]] || { echo "compile-check: headless sway failed to start"; tail -5 "$T/sway.log"; exit 2; }
rc=0
for fam in "${fams[@]}"; do
  cat > "$T/ii/shell.qml" <<QML
//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import Quickshell
import "panelFamilies"
ShellRoot {
    Component { id: c; $fam {} }
    Component.onCompleted: console.log("COMPILE-CHECK $fam status=" + c.status + (c.status === Component.Error ? " " + c.errorString() : ""))
}
QML
  out=$("${base_env[@]}" WAYLAND_DISPLAY="$WL" QT_QPA_PLATFORM=wayland QML_IMPORT_PATH="$HOME/.local/lib/qt6/qml" \
        dbus-run-session -- timeout 25 qs -p "$T/ii/shell.qml" --no-color 2>&1)
  if grep -q "COMPILE-CHECK $fam status=1" <<<"$out"; then
    echo "compile-check $fam: OK"
  else
    echo "compile-check $fam: FAIL"; grep -E 'ERROR|caused by|COMPILE-CHECK|is not a type|non-existent' <<<"$out" | tail -12; rc=1
  fi
done
exit $rc

#!/usr/bin/env bash
# Compile-check panel families WITHOUT running them on the real desktop.
# A throwaway copy of the ii tree gets a shell.qml that only declares `Component { <Family> {} }`
# (never instantiated): QML resolves/compiles the whole type tree (catches "Type X unavailable",
# "non-existent property", bad imports) but creates no services.
# Isolation: fake HOME/XDG dirs, private D-Bus session, and a private HEADLESS sway compositor
# (no screen, no input devices, socket inside the sandbox). Quickshell's PanelWindow needs layer-shell,
# so plain QT_QPA_PLATFORM=offscreen can't be used.
# Requires: sway (only as this invisible test compositor), dbus-run-session. Without sway (removed 2026-10-12) it
# connects to the running compositor instead: safe, because the family is only compiled, never instantiated (no
# windows, shortcuts or services); HOME/XDG and D-Bus stay sandboxed.
# Usage: tools/compile-check.sh [Family ...]   (default: CaelestiaFamily)
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
HOST_WL=""
if ! command -v sway >/dev/null; then
  [[ -n "${WAYLAND_DISPLAY:-}" && -n "${XDG_RUNTIME_DIR:-}" ]] || { echo "compile-check: needs sway or a running Wayland session"; exit 2; }
  HOST_WL="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" # absolute socket path: works with the sandboxed XDG_RUNTIME_DIR
fi
fams=("$@"); [[ $# -eq 0 ]] && fams=(CaelestiaFamily)
T=$(mktemp -d "${TMPDIR:-/tmp}/c4-compile.XXXXXX"); trap 'kill "${SWAY_PID:-}" 2>/dev/null; rm -rf "$T"' EXIT
rsync -a --exclude '.git' dots/.config/quickshell/ii/ "$T/ii/"
# A linked worktree, fresh clone or git archive has its submodules empty, and with shapes/*.js missing Qt 6.12's type
# loader segfaults on this tree instead of reporting an error. Fill the throwaway copy at the pinned commit, from the
# objects the main checkout already has (no network, the tree is left alone); stop if there is no way to.
while read -r key path; do
  [[ "$path" == dots/.config/quickshell/ii/* ]] || continue
  [[ -n "$(ls -A "$path" 2>/dev/null)" ]] && continue
  name=${key#submodule.}; name=${name%.path}
  mod="$(git rev-parse --git-common-dir 2>/dev/null)/modules/$name"
  sha=$(git rev-parse ":$path" 2>/dev/null)
  if [[ -z "$sha" ]] || ! git -C "$mod" cat-file -e "$sha^{commit}" 2>/dev/null; then
    echo "compile-check: submodule $path is empty and its pinned commit isn't available here."
    echo "In a git checkout run: git submodule update --init -- $path"
    exit 2
  fi
  git -C "$mod" archive "$sha" | tar -x -C "$T/ii/${path#dots/.config/quickshell/ii/}"
done < <(git config -f .gitmodules --get-regexp '\.path$')
mkdir -p "$T/home"/{.config,.local/state,.cache,.local/share} "$T/run"; chmod 700 "$T/run"
: > "$T/sway.conf"
export -n WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE
base_env=(env -i PATH="$PATH" HOME="$T/home" XDG_CONFIG_HOME="$T/home/.config" XDG_STATE_HOME="$T/home/.local/state"
  XDG_CACHE_HOME="$T/home/.cache" XDG_DATA_HOME="$T/home/.local/share" XDG_RUNTIME_DIR="$T/run")
if [[ -n "$HOST_WL" ]]; then
  WL="$HOST_WL"
else
  "${base_env[@]}" WLR_BACKENDS=headless WLR_HEADLESS_OUTPUTS=1 WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman \
    sway -c "$T/sway.conf" >"$T/sway.log" 2>&1 &
  SWAY_PID=$!
  for _ in $(seq 1 50); do ls "$T/run"/wayland-* >/dev/null 2>&1 && break; sleep 0.1; done
  WL=$(basename "$(ls "$T/run"/wayland-[0-9] 2>/dev/null | head -1)")
  [[ -n "$WL" ]] || { echo "compile-check: headless sway failed to start"; tail -5 "$T/sway.log"; exit 2; }
fi
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
  # QS_DISABLE_CRASH_HANDLER: its crash reporter is a window on the compositor we're connected to, and it would hold
  # this pipe open until someone closed it. A crash leaves a coredump and shows up as the message below instead.
  out=$("${base_env[@]}" WAYLAND_DISPLAY="$WL" QT_QPA_PLATFORM=wayland QML_IMPORT_PATH="$HOME/.local/lib/qt6/qml" QS_DISABLE_CRASH_HANDLER=1 \
        dbus-run-session -- timeout 25 qs -p "$T/ii/shell.qml" --no-color 2>&1); qs_status=$?
  if grep -q "COMPILE-CHECK $fam status=1" <<<"$out"; then
    echo "compile-check $fam: OK"
  else
    echo "compile-check $fam: FAIL"; grep -E 'ERROR|caused by|COMPILE-CHECK|is not a type|non-existent' <<<"$out" | tail -12; rc=1
    (( qs_status > 128 && qs_status < 255 )) && echo "  qs was killed by signal $((qs_status - 128)) (see: coredumpctl list quickshell)"
  fi
done
exit $rc

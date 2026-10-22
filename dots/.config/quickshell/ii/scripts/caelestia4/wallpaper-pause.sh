#!/usr/bin/env bash
# caelestia4: pause / play the video wallpaper (Caelestia's "wallpaper playing" quick toggle, upstream b7959294).
# end-4's switchwall.sh starts one mpvpaper per monitor with an mpv IPC socket
# ($XDG_RUNTIME_DIR/caelestia4-mpvpaper-<monitor>.sock); this sets mpv's "pause" property on each of them.
# The choice is kept in $XDG_STATE_HOME/caelestia4/wallpaper-paused (present = paused), so a video wallpaper restored
# at login, or newly picked, starts paused too.
# Usage: wallpaper-pause.sh [toggle|pause|play|status]   (status prints "paused" or "playing")
state="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia4/wallpaper-paused"

send() { # send <true|false>
    local sock
    for sock in "${XDG_RUNTIME_DIR:-/run/user/$UID}"/caelestia4-mpvpaper-*.sock; do
        [[ -S "$sock" ]] || continue
        printf '{"command":["set_property","pause",%s]}\n' "$1" | socat -t 1 - "UNIX-CONNECT:$sock" >/dev/null 2>&1
    done
}

case "${1:-toggle}" in
    pause) mkdir -p "$(dirname "$state")"; : > "$state"; send true ;;
    play) rm -f -- "$state"; send false ;;
    toggle) if [[ -e "$state" ]]; then "$0" play; else "$0" pause; fi ;;
    status) [[ -e "$state" ]] && echo paused || echo playing ;;
    *) echo "usage: $0 [toggle|pause|play|status]" >&2; exit 2 ;;
esac

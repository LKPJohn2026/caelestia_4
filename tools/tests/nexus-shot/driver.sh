#!/usr/bin/env bash
# caelestia4 Nexus screenshots: runs INSIDE the bwrap sandbox that run.sh builds
set -uo pipefail
L=/t/logs R=/run/user/1000
log() { printf '[%s] %s\n' "$(date +%T.%3N)" "$*" >> "$L/driver.log"; }
die() { echo "nexus-shot: $*" >&2; log "FAIL $*"; exit 1; }
wait_until() { local n=$(( $1 * 5 )) i; shift; for ((i = 0; i < n; i++)); do "$@" && return 0; sleep 0.2; done; return 1; }

# nothing in here may reach the real screen, keyboard, session or home
[[ "$(cd /dev/dri && echo *)" == "card1 renderD128" ]] || die "unsafe sandbox (dri)"
[[ ! -e /dev/input && ! -e /run/dbus && ! -e /run/systemd && ! -e /home && $HOME == /t/home ]] || die "unsafe sandbox"
for s in /sys/class/drm/card1-*/status; do [[ $s == *Writeback* || $(<"$s") == disconnected ]] || die "card1 has a screen"; done

SEATD_VTBOUND=0 seatd -l info > "$L/seatd.out" 2>&1 &
wait_until 5 test -S /run/seatd.sock || die "seatd did not start"
env LIBSEAT_BACKEND=seatd AQ_DRM_DEVICES=/dev/dri/card1 HYPRLAND_NO_SD_NOTIFY=1 HYPRLAND_NO_SD_VARS=1 \
    HYPRLAND_NO_SD_TARGET=1 HYPRLAND_NO_CRASHREPORTER=1 Hyprland -c /t/hyprland.lua > "$L/hypr.out" 2>&1 &
wait_until 15 compgen -G "$R/hypr/*/.socket.sock" > /dev/null || die "Hyprland did not start"
HYPRLAND_INSTANCE_SIGNATURE=$(basename "$(dirname "$(compgen -G "$R/hypr/*/.socket.sock")")"); export HYPRLAND_INSTANCE_SIGNATURE
wait_until 5 compgen -G "$R/wayland-[0-9]" > /dev/null || die "no Wayland socket"
WAYLAND_DISPLAY=$(basename "$(compgen -G "$R/wayland-[0-9]" | head -1)"); export WAYLAND_DISPLAY
hyprctl output create headless TEST-1 > /dev/null
wait_until 5 eval 'hyprctl -j monitors | jq -e "any(.[]; .name == \"TEST-1\")" > /dev/null' || die "no TEST-1"

QT_QPA_PLATFORM=wayland QML_IMPORT_PATH=/t/qml QS_DISABLE_CRASH_HANDLER=1 qs -c ii --no-color --log-times > "$L/qs.out" 2>&1 &
wait_until 60 eval 'qs -c ii ipc show 2>/dev/null | grep -q "target nexus"' || die "no nexus IPC (logs/qs.out)"
sleep 4 # the shell's start-up (config, colours, fonts)
has_openat=0; qs -c ii ipc show | grep -A8 'target nexus' | grep -q 'openAt' && has_openat=1

winsize=''; [[ -f /t/winsize ]] && winsize=$(</t/winsize)
# -w: resize the window (this sandbox's Hyprland only) and centre it on TEST-1
resize() {
    local addr w=${winsize%x*} h=${winsize#*x} mw mh
    addr=$(hyprctl -j clients | jq -r 'map(select(.title | startswith("Nexus — "))) | .[0].address // empty')
    [[ -n $addr ]] || return 1
    read -r mw mh < <(hyprctl -j monitors | jq -r '.[0] | "\(.width) \(.height)"')
    hyprctl dispatch "hl.dsp.window.resize({ x = $w, y = $h, \"exact\", window = \"address:$addr\" })" >> "$L/ipc.out" 2>&1
    hyprctl dispatch "hl.dsp.window.move({ x = $(((mw - w) / 2)), y = $(((mh - h) / 2)), window = \"address:$addr\" })" >> "$L/ipc.out" 2>&1
}
geom() { hyprctl -j clients | jq -r 'map(select(.title | startswith("Nexus — "))) | .[0] | select(.) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'; }
n=0
while IFS= read -r spec; do
    n=$((n + 1))
    if ((has_openat)) && [[ -n $spec ]]; then qs -c ii ipc call nexus openAt "$spec" >> "$L/ipc.out" 2>&1
    else qs -c ii ipc call nexus open >> "$L/ipc.out" 2>&1; fi
    wait_until 10 eval '[[ -n "$(geom)" ]]' || die "no Nexus window for '$spec'"
    if [[ -n $winsize ]]; then resize || log "resize failed for $spec"; sleep 0.5; fi
    sleep 1.5 # page transitions, images
    name=$(printf '%02d-%s' "$n" "${spec:-open}" | tr '/#: ' '____')
    grim -g "$(geom)" "/t/out/$name.png" 2>> "$L/grim.err" || log "grim failed for $spec"
    log "shot $name ($(geom))"
done < /t/specs
grep -E 'WARN|ERROR|TypeError|ReferenceError' "$L/qs.out" | grep -iE 'nexus|/common/' > /t/out/qs-errors.txt
exit 0

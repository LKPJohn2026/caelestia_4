#!/usr/bin/env bash
# caelestia4 Nexus screenshots: opens the Nexus settings window in a test Hyprland and shoots it, without touching the
# desktop. Sandbox: bubblewrap, fake HOME, private buses, stub commands (stubs/), and a second Hyprland on the AMD iGPU
# card1 that has no screen connected (headless output TEST-1, no input devices).
#
# Usage: tools/tests/nexus-shot/run.sh [-o DIR] [-m WxH] [-w WxH] [-s FILE] [-c FILE] [-t DIR] [--keep] [SPEC...]
#   SPEC  where to open, as `nexus openAt` takes it (e.g. "appearance", "hyprland/general", "services#weather");
#         "" or none: the window as it opens. Each spec gives DIR/NN-<spec>.png
#   -o    where the pictures go (default: a new /tmp/c4nexus.XXXXXX/out)    -m    TEST-1's mode (default 1920x1080)
#   -w    resize the Nexus window to WxH before each shot (in the test Hyprland only; the sandbox's shell-tokens.json
#         lowers Nexus's minimum size so small layouts can be shot)
#   -s    a Caelestia shell.json for the sandbox (~/.config/caelestia/shell.json; default: none, so all defaults)
#   -c    an end-4 config.json for the sandbox (~/.config/illogical-impulse/config.json; default: lock off, no widgets)
#   -t    shoot this copy of the quickshell ii tree instead of the repo's dots/.config/quickshell/ii (for a throwaway
#         experiment that must not touch the working tree)
# Also writes DIR/qs-errors.txt: the shell's warnings and errors from Nexus files (empty = none).
set -uo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$here/../../.." || exit 2
out='' mode=1920x1080 win='' keep=0 specs=() shelljson='' configjson='' tree=dots/.config/quickshell/ii
while (($#)); do
    case $1 in
        -o) out=$2; shift 2 ;;
        -m) mode=$2; shift 2 ;;
        -w) win=$2; shift 2 ;;
        -s) shelljson=$(realpath -e -- "$2") || exit 2; shift 2 ;;
        -c) configjson=$(realpath -e -- "$2") || exit 2; shift 2 ;;
        -t) tree=$(realpath -e -- "$2") || exit 2; shift 2 ;;
        --keep) keep=1; shift ;;
        *) specs+=("$1"); shift ;;
    esac
done
((${#specs[@]})) || specs=("")

# one run at a time: they share card1 (a second Hyprland on it would fail to start)
exec 9> /tmp/c4-nexus-shot.lock
flock 9
for s in /sys/class/drm/card1-*/status; do
    [[ $s == *Writeback* || $(<"$s") == disconnected ]] || { echo "nexus-shot: $s is $(<"$s"); refusing"; exit 3; }
done
busy=$(find /proc/[0-9]*/fd -maxdepth 1 -lname /dev/dri/card1 -print -quit 2>/dev/null)
[[ -z $busy ]] || { busy=${busy#/proc/}; echo "nexus-shot: process ${busy%%/*} has /dev/dri/card1 open; refusing"; exit 3; }
[[ -c /dev/dri/renderD128 ]] || { echo "nexus-shot: no /dev/dri/renderD128"; exit 3; }

source tools/lib-fill-submodules.sh
T=$(mktemp -d /tmp/c4nexus.XXXXXX)
[[ -n $out ]] || out=$T/out
mkdir -p "$out" "$T"/{run,logs,bin,home/.config/{illogical-impulse,hypr,quickshell},home/.local/{state,share},home/.cache}
chmod 700 "$T/run"
rsync -a --exclude .git --exclude __pycache__ "$tree/" "$T/home/.config/quickshell/ii/"
fill_submodules "$T/home/.config/quickshell/ii" || exit 2
sed "s/@MODE@/$mode/" "$here/hyprland.lua" > "$T/hyprland.lua"
cp -a "$here/driver.sh" "$T/bin/"
cp -a "$here/stubs" "$T/"
sed '/<standard_session_servicedirs/d' /usr/share/dbus-1/session.conf > "$T/dbus.conf"
printf '%s\n' "${specs[@]}" > "$T/specs"
if [[ -n $win ]]; then
    [[ $win =~ ^[0-9]+x[0-9]+$ ]] || { echo "nexus-shot: -w wants WxH, not '$win'"; exit 2; }
    echo "$win" > "$T/winsize"
    mkdir -p "$T/home/.config/caelestia"
    echo '{"sizes":{"nexus":{"minWidth":320,"minHeight":320}}}' > "$T/home/.config/caelestia/shell-tokens.json"
fi
if [[ -n $configjson ]]; then cp -- "$configjson" "$T/home/.config/illogical-impulse/config.json"
else echo '{"lock":{"launchOnStartup":false},"background":{"widgets":{}}}' > "$T/home/.config/illogical-impulse/config.json"; fi
[[ -z $shelljson ]] || { mkdir -p "$T/home/.config/caelestia" && cp -- "$shelljson" "$T/home/.config/caelestia/shell.json"; }

timeout $((60 + 8 * ${#specs[@]})) bwrap --unshare-all --die-with-parent --new-session \
    --ro-bind /usr /usr --symlink usr/lib /lib --symlink usr/lib /lib64 --symlink usr/bin /bin --symlink usr/bin /sbin \
    --ro-bind /etc /etc --ro-bind /sys /sys --ro-bind-try /var/cache/fontconfig /var/cache/fontconfig \
    --proc /proc --dev /dev --dev-bind /dev/dri/renderD128 /dev/dri/renderD128 --dev-bind /dev/dri/card1 /dev/dri/card1 \
    --tmpfs /run --ro-bind /run/udev /run/udev --tmpfs /tmp --bind "$T" /t --bind "$T/run" /run/user/1000 \
    --bind "$out" /t/out --ro-bind "$HOME/.local/lib/qt6/qml" /t/qml \
    --clearenv --setenv PATH /t/stubs:/usr/bin --setenv HOME /t/home --setenv XDG_RUNTIME_DIR /run/user/1000 \
    --setenv XDG_CONFIG_HOME /t/home/.config --setenv XDG_STATE_HOME /t/home/.local/state \
    --setenv XDG_CACHE_HOME /t/home/.cache --setenv XDG_DATA_HOME /t/home/.local/share \
    --setenv XDG_CURRENT_DESKTOP Hyprland --setenv XDG_SESSION_TYPE wayland --setenv LANG C.UTF-8 \
    dbus-run-session --config-file=/t/dbus.conf -- bash /t/bin/driver.sh 2>> "$T/logs/sandbox.err"
rc=$?
ls "$out"/*.png 2>/dev/null
echo "nexus-shot: exit $rc; pictures in $out${keep:+}"
if ((rc || keep)); then echo "logs: $T/logs"; else rm -rf -- "${T:?}/home" "${T:?}/run"; fi
exit $rc

#!/usr/bin/env bash
# Golden-file tests for the config migrations in tools/install-main.sh: the old AQ_DRM_DEVICES lines it takes out of
# hypr/custom/env.lua, and its rewrites of xdg-desktop-portal/hyprland-portals.conf (FileChooser to Wormhole, KDE-only
# interfaces off, the pins an older file lacks, RemoteDesktop to or from hypr-kdeconnect). The sed and python snippets
# are taken from install-main.sh as they are (extract.py), so this tests the installer's own code, and run on fixture
# files in a temporary directory; nothing else of the installer runs. Each migration must give the expected file, leave
# other lines alone, and change nothing when run again.
# Usage: tools/tests/install-migrations/run.sh
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../.." && pwd)
src="$repo/tools/install-main.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# A home of its own, so a statement that ever names a file under it can't reach the real one
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config"
mkdir -p "$XDG_CONFIG_HOME"

fails=0
ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails + 1)); }

# snippet NEEDLE: the one sed statement of install-main.sh holding NEEDLE (continued lines joined)
snippet() { python3 -I "$here/extract.py" sed "$src" "$1"; }
# The statements, each run with ENV and CFG pointing at the fixtures
sed_card1=$(snippet '/dev\/dri\/card1')
sed_dgpu=$(snippet 'nvidia-dgpu')
sed_portals=$(snippet 'FileChooser = wormhole;gtk/')
sed_kdeconnect_on=$(snippet '= none$/\1 = hypr-kdeconnect/')
sed_kdeconnect_off=$(snippet '= hypr-kdeconnect$/\1 = none/')
pins_py=$(python3 -I "$here/extract.py" heredoc "$src" 'python3 - "$DOTS/xdg-desktop-portal/hyprland-portals.conf"')
for v in sed_card1 sed_dgpu sed_portals sed_kdeconnect_on sed_kdeconnect_off pins_py; do
  [[ -n ${!v} ]] || { echo "FAIL: $v not found in install-main.sh"; echo "install-migrations tests: FAILED"; exit 1; }
done
# Each statement is run with eval, so it must end in exactly the file it is meant for (then at most the installer's
# '2>/dev/null || true'): a statement aimed anywhere else is not run at all
target() {
  local v=$1 want=$2 s=${!1}
  s=${s%' 2>/dev/null || true'}
  [[ $s == *" $want" ]] || { echo "FAIL: $v doesn't end in $want: $s"; echo "install-migrations tests: FAILED"; exit 1; }
}
target sed_card1 '"$ENV"'
target sed_dgpu '"$ENV"'
for v in sed_portals sed_kdeconnect_on sed_kdeconnect_off; do
  target "$v" '"$CFG/xdg-desktop-portal/hyprland-portals.conf"'
done

ENV="$tmp/env.lua"
CFG="$tmp/cfg"
DOTS="$repo/dots/.config"
mkdir -p "$CFG/xdg-desktop-portal"
portals="$CFG/xdg-desktop-portal/hyprland-portals.conf"
run() { (eval "$1"); }
run_pins() { python3 -I -c "$pins_py" "$DOTS/xdg-desktop-portal/hyprland-portals.conf" "$portals"; }

# migrate NAME FILE INPUT EXPECTED CMD: FILE from INPUT, CMD run on it twice, FILE compared with EXPECTED each time
migrate() {
  local name=$1 file=$2 input=$3 want=$4 cmd=$5 pass
  printf '%s\n' "$input" >"$file"
  for pass in first again; do
    "$cmd"
    if [[ $(cat "$file") == "$want" ]]; then
      ok "$name ($pass run)"
    else
      bad "$name ($pass run):"$'\n'"$(diff <(printf '%s\n' "$want") "$file" | sed 's/^/    /')"
    fi
  done
}

# ---- hypr/custom/env.lua. The comment lines are the ones the sed expressions match, read from them
card1_comment=$(python3 -I "$here/extract.py" sed-address "$sed_card1")
dgpu_comment=$(python3 -I "$here/extract.py" sed-address "$sed_dgpu")
[[ $card1_comment == "-- caelestia4: "* && $dgpu_comment == "-- caelestia4: "* ]] \
  || { echo "FAIL: couldn't read the comments ('$card1_comment', '$dgpu_comment')"; echo "install-migrations tests: FAILED"; exit 1; }
card1='hl.env("AQ_DRM_DEVICES", "/dev/dri/card1")'
dgpu='hl.env("AQ_DRM_DEVICES", "/dev/dri/nvidia-dgpu")'
env_in="-- my own settings
hl.env(\"FOO\", \"bar\")
$card1_comment
$card1

-- caelestia4: user-local Caelestia QML plugin, visible to Quickshell in this session only
hl.env(\"QML_IMPORT_PATH\", os.getenv(\"HOME\") .. \"/.local/lib/qt6/qml\")
$dgpu_comment
$dgpu
$dgpu_comment
hl.env(\"AQ_DRM_DEVICES\", \"/dev/dri/card0\")
$dgpu
-- a card1 line of my own
$card1"

step_card1() { run "$sed_card1"; }
step_dgpu() { run "$sed_dgpu"; }
step_both() { run "$sed_card1"; run "$sed_dgpu"; }
migrate "env.lua: the old card1 pair goes" "$ENV" "$env_in" "-- my own settings
hl.env(\"FOO\", \"bar\")

-- caelestia4: user-local Caelestia QML plugin, visible to Quickshell in this session only
hl.env(\"QML_IMPORT_PATH\", os.getenv(\"HOME\") .. \"/.local/lib/qt6/qml\")
$dgpu_comment
$dgpu
$dgpu_comment
hl.env(\"AQ_DRM_DEVICES\", \"/dev/dri/card0\")
$dgpu
-- a card1 line of my own
$card1" step_card1
migrate "env.lua: the old nvidia-dgpu pair goes, a changed one and lines of your own stay" "$ENV" "$env_in" \
  "-- my own settings
hl.env(\"FOO\", \"bar\")
$card1_comment
$card1

-- caelestia4: user-local Caelestia QML plugin, visible to Quickshell in this session only
hl.env(\"QML_IMPORT_PATH\", os.getenv(\"HOME\") .. \"/.local/lib/qt6/qml\")
$dgpu_comment
hl.env(\"AQ_DRM_DEVICES\", \"/dev/dri/card0\")
$dgpu
-- a card1 line of my own
$card1" step_dgpu
migrate "env.lua: both, in the installer's order" "$ENV" "$env_in" "-- my own settings
hl.env(\"FOO\", \"bar\")

-- caelestia4: user-local Caelestia QML plugin, visible to Quickshell in this session only
hl.env(\"QML_IMPORT_PATH\", os.getenv(\"HOME\") .. \"/.local/lib/qt6/qml\")
$dgpu_comment
hl.env(\"AQ_DRM_DEVICES\", \"/dev/dri/card0\")
$dgpu
-- a card1 line of my own
$card1" step_both
current='-- caelestia4: user-local Caelestia QML plugin, visible to Quickshell in this session only
hl.env("QML_IMPORT_PATH", os.getenv("HOME") .. "/.local/lib/qt6/qml")'
migrate "env.lua: a current file is left as it is" "$ENV" "$current" "$current" step_both

# ---- xdg-desktop-portal/hyprland-portals.conf
p=org.freedesktop.impl.portal
step_portals() { run "$sed_portals"; }
migrate "portals: the old KDE defaults move" "$portals" "[preferred]
default = hyprland;gtk
$p.FileChooser = kde
$p.Background = kde
$p.Clipboard = kde
$p.Usb = kde
$p.Wallpaper = kde
$p.Inhibit = kde
$p.Settings = darkman;gtk
# $p.Usb = kde" "[preferred]
default = hyprland;gtk
$p.FileChooser = wormhole;gtk
$p.Background = none
$p.Clipboard = none
$p.Usb = none
$p.Wallpaper = none
$p.Inhibit = kde
$p.Settings = darkman;gtk
# $p.Usb = kde" step_portals
migrate "portals: Wormhole then KDE moves to Wormhole then GTK" "$portals" "$p.FileChooser = wormhole;kde" \
  "$p.FileChooser = wormhole;gtk" step_portals
yours="$p.FileChooser = gtk
$p.Background = gtk
$p.Wallpaper = kde;gtk"
migrate "portals: values you chose stay" "$portals" "$yours" "$yours" step_portals

# The pins an older file lacks, added from the installed default (and nothing it already has)
old="[preferred]
default = hyprland;gtk
$p.FileChooser = gtk
$p.Background = gtk"
migrate "portals: missing pins added, existing ones kept" "$portals" "$old" "$old
$(grep -v '^#' "$DOTS/xdg-desktop-portal/hyprland-portals.conf" | grep '=' \
  | grep -v -e '^default *=' -e "^$p\.FileChooser *=" -e "^$p\.Background *=")" run_pins
cp "$DOTS/xdg-desktop-portal/hyprland-portals.conf" "$tmp/default.conf"
migrate "portals: the current default gets nothing added" "$portals" "$(cat "$tmp/default.conf")" "$(cat "$tmp/default.conf")" run_pins

# RemoteDesktop: to hypr-kdeconnect while its portal is installed, back to none when it's gone
step_on() { run "$sed_kdeconnect_on"; }
step_off() { run "$sed_kdeconnect_off"; }
others="$p.FileChooser = wormhole;gtk
$p.Secret = gnome-keyring"
migrate "portals: RemoteDesktop to hypr-kdeconnect" "$portals" "$others
$p.RemoteDesktop = none" "$others
$p.RemoteDesktop = hypr-kdeconnect" step_on
migrate "portals: RemoteDesktop back to none" "$portals" "$others
$p.RemoteDesktop = hypr-kdeconnect" "$others
$p.RemoteDesktop = none" step_off
migrate "portals: a RemoteDesktop you chose stays" "$portals" "$p.RemoteDesktop = gnome" "$p.RemoteDesktop = gnome" step_on
migrate "portals: a RemoteDesktop you chose stays (off)" "$portals" "$p.RemoteDesktop = gnome" "$p.RemoteDesktop = gnome" step_off

if ((fails)); then
  echo "install-migrations tests: $fails FAILED"
  exit 1
fi
echo "install-migrations tests: OK"

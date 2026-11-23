#!/usr/bin/env bash
# caelestia4: a wallpaper's path never reaches a generated config with a line break in it. hyprlock's colors.conf has
# `$background_image = {{image}}` (matugen/templates/hyprland/hyprlock-colors.conf), so a file named
# "a<newline>label { text = cmd[...] }" would add a label that runs a command at every lock.
#  1. scripts/colors/switchwall.sh refuses such a path (--image, and --noswitch with one saved): exit 1, a
#     notification, the saved wallpaper unchanged, no matugen, no mpvpaper killed. A normal path still goes through.
#  2. scheme.py's wallpaper_path() (what caelestia-cli's postHook gives matugen as {{image}}) is "" for one.
#  3. Each hyprland matugen template that uses {{image}} is only fed by those two (static check).
# A fake HOME and a PATH of stubs and a few real tools only (no Hyprland, matugen, caelestia-cli or mpvpaper reached).
# Usage: tools/tests/wallpaper-path/run.sh
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
ii="$repo/dots/.config/quickshell/ii"
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
fails=0
ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails + 1)); }

bin="$tmp/bin" home="$tmp/home" log="$tmp/calls.log"
mkdir -p "$bin" "$home/.config/illogical-impulse" "$tmp/walls"
for t in bash sh jq sed cat mv mkdir chmod dirname readlink basename xargs tr date sleep rm grep env python3; do
  p=$(command -v "$t") || { echo "FAIL: $t is needed"; exit 1; }
  ln -s "$p" "$bin/$t"
done
stub() { printf '#!/bin/sh\necho "%s $*" >>"%s"\n%s\n' "$1" "$log" "${2:-}" >"$bin/$1" && chmod +x "$bin/$1"; }
stub notify-send
stub matugen
stub pkill
stub gsettings
stub kitty
stub uwsm-app
stub bc 'cat >/dev/null; echo 0'
stub hyprctl 'case "$1" in monitors) echo "[{\"focused\":true,\"scale\":1,\"x\":0,\"y\":0,\"height\":1}]";; *) echo "{\"x\":0,\"y\":0}";; esac'
stub xdg-user-dir "echo $tmp/walls"

cfg="$home/.config/illogical-impulse/config.json"
config() { # config WALLPAPER: a config.json that stops switchwall.sh before matugen and the colour scripts
  jq -n --arg w "$1" '{background: {wallpaperPath: $w, wallpaperFit: {enable: true}, widgets: {clock: {cookie: {aiStyling: false}}}},
    appearance: {palette: {type: "scheme-tonal-spot", accentColor: ""}, wallpaperTheming: {enableAppsAndShell: false}}}' >"$cfg"
}
switchwall() { env -i PATH="$bin" HOME="$home" LANG=C.UTF-8 bash "$ii/scripts/colors/switchwall.sh" "$@" >/dev/null 2>&1; }

good="$tmp/walls/good.png" evil="$tmp/walls/a.png"$'\n''label {'$'\n''    text = cmd[update:0] touch pwned'$'\n''}'$'\n''#.png'
printf 'x' >"$good"
printf 'x' >"$evil"

# 1. switchwall.sh
config "$good"; : >"$log"
code=0; switchwall --image "$evil" || code=$?
[[ $code -eq 1 ]] && ok "--image with a line break: exit 1" || bad "--image with a line break: exit $code"
[[ "$(jq -r .background.wallpaperPath "$cfg")" == "$good" ]] && ok "the saved wallpaper is unchanged" || bad "the path was saved"
grep -q '^notify-send ' "$log" && ok "a notification says why" || bad "no notification"
grep -qE '^(matugen|pkill|uwsm-app) ' "$log" && bad "it went on: $(cat "$log")" || ok "no matugen, nothing killed or started"

config "$evil"; : >"$log"
code=0; switchwall --noswitch || code=$?
[[ $code -eq 1 ]] && ! grep -q '^matugen ' "$log" && ok "--noswitch with one saved: exit 1, no matugen" || bad "--noswitch: exit $code, $(cat "$log")"

config "$tmp/walls/old.png"; : >"$log"
code=0; switchwall --image "$good" || code=$?
[[ $code -eq 0 && "$(jq -r .background.wallpaperPath "$cfg")" == "$good" ]] &&
  ok "a normal path still becomes the wallpaper" || bad "a normal path: exit $code, saved $(jq -r .background.wallpaperPath "$cfg")"

# 2. scheme.py
config "$evil"
got=$(env -i HOME="$home" XDG_CONFIG_HOME="$home/.config" python3 -I -c '
import importlib.util, sys
spec = importlib.util.spec_from_file_location("scheme", sys.argv[1]); m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m); print(repr(m.wallpaper_path()))' "$ii/modules/caelestia/utils/scripts/scheme.py")
[[ "$got" == "''" ]] && ok "scheme.py: no wallpaper for a path with a line break" || bad "scheme.py gave $got"
config "$good"
got=$(env -i HOME="$home" XDG_CONFIG_HOME="$home/.config" python3 -I -c '
import importlib.util, sys
spec = importlib.util.spec_from_file_location("scheme", sys.argv[1]); m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m); print(m.wallpaper_path())' "$ii/modules/caelestia/utils/scripts/scheme.py")
[[ "$got" == "$good" ]] && ok "scheme.py: a normal path as it is" || bad "scheme.py gave $got for a normal path"

# 3. Static: who feeds {{image}}
# (wallpaper.txt is the path alone, as text)
users=$(cd "$repo/dots/.config/matugen/templates" && grep -rl '{{image}}' . | sort | tr '\n' ' ' || true)
[[ "$users" == "./hyprland/hyprlock-colors.conf ./wallpaper.txt " ]] &&
  ok "{{image}} only in hyprlock-colors.conf and wallpaper.txt" || bad "{{image}} templates changed, check what feeds them: $users"
grep -q '"\$imgpath" == \*\[\[:cntrl:\]\]\*' "$ii/scripts/colors/switchwall.sh" && ok "switchwall.sh has its check" || bad "switchwall.sh lost its check"

if ((fails)); then echo "wallpaper-path tests: $fails FAILED"; exit 1; fi
echo "wallpaper-path tests: OK"

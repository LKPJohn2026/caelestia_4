#!/usr/bin/env bash
# Checks that Hyprland's session_lock_xray stays off in the shipped config, and that the lock screen draws its own
# backdrop for it. The shell's lock surface is transparent: with xray on, a window opened or pinned while locked (or
# every window, when the move to an empty workspace didn't happen) shows through it. With xray off nothing of the
# desktop is drawn under the lock, not even the background layer, so the lock surface draws the wallpaper and the
# lock's widgets itself (modules/ii/lock/LockBackdrop.qml), opaque and without input. Reads the files only.
# Usage: tools/tests/lock-xray/run.sh
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
qs=$root/dots/.config/quickshell/ii
fails=0
ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails + 1)); }

f=$root/dots/.config/hypr/hyprland/general.lua
# The setting lines, comments left out
lines=$(sed 's/--.*//' "$f" | grep -E '\bsession_lock_xray\b' || true)
off='^[[:space:]]*session_lock_xray[[:space:]]*=[[:space:]]*false[[:space:]]*,?[[:space:]]*$'
if [[ $(wc -l <<<"$lines") -eq 1 && $lines =~ $off ]]; then ok "session_lock_xray = false, once"
else bad "${f#"$root"/} must set session_lock_xray = false, once"; fi

# QML without // comments, one file
code() { sed 's://.*::' "$1"; }

screen=$(code "$qs/modules/common/panels/lock/LockScreen.qml")
# the backdrop's Loader comes before (under) the lock surface's own, in the session-lock surface
surface=$(awk '/WlSessionLockSurface \{/,/^    \}$/' <<<"$screen")
if grep -q 'sourceComponent: root.backdrop' <<<"$surface" &&
  [[ $(grep -n 'sourceComponent: root.backdrop' <<<"$surface" | cut -d: -f1) -lt \
    $(grep -n 'sourceComponent: root.lockSurface' <<<"$surface" | cut -d: -f1) ]]; then
  ok "the session-lock surface loads the backdrop under the lock surface"
else bad "LockScreen.qml's WlSessionLockSurface doesn't load root.backdrop before root.lockSurface"; fi
grep -q 'item.screen = Qt.binding(() => sessionLockSurface.screen)' <<<"$surface" \
  && ok "the backdrop is told its screen" || bad "the backdrop isn't given the surface's screen"

grep -qE '^[[:space:]]*backdrop: LockBackdrop \{' <(code "$qs/modules/ii/lock/Lock.qml") \
  && ok "the ii lock sets its backdrop" || bad "modules/ii/lock/Lock.qml doesn't set backdrop: LockBackdrop"

b=$qs/modules/ii/lock/LockBackdrop.qml
if [[ -f $b ]]; then
  back=$(code "$b")
  # an opaque fill first (while the picture loads, or when it is missing), then the wallpaper, then the widgets
  first=$(grep -m1 -nE '^    [A-Z][A-Za-z.]* \{' <<<"$back" || true)
  [[ $first == *"Rectangle {" ]] &&
    grep -A3 '^    Rectangle {' <<<"$back" | grep -qE 'color: Appearance\.colors\.colLayer0Base[[:space:]]*$' &&
    ok "the backdrop starts with an opaque fill" || bad "LockBackdrop.qml doesn't start with an opaque Rectangle"
  # colLayer0Base, not colLayer0: Appearance.qml makes colLayer0 see-through by the transparency setting
  app=$(code "$qs/modules/common/Appearance.qml")
  if grep -qE 'property color colLayer0Base: ColorUtils\.mix\(m3colors\.m3background, m3colors\.m3primary,' <<<"$app" &&
    ! grep -E 'property color colLayer0Base:' <<<"$app" | grep -qiE 'transparentize|backgroundTransparency|alpha'; then
    ok "the fill's colour (colLayer0Base) has no transparency in it"
  else bad "Appearance.colors.colLayer0Base isn't the opaque mix of the background and primary colours"; fi
  grep -q 'CA.Wallpapers.forScreen(root.screen)' <<<"$back" && ok "it draws the screen's wallpaper" \
    || bad "LockBackdrop.qml doesn't draw Wallpapers.forScreen(root.screen)"
  if grep -A8 'CB.PcWidgetsLoader {' <<<"$back" | grep -q 'enabled: false'; then
    ok "it draws the desktop widgets, without input"
  else bad "LockBackdrop.qml doesn't draw PcWidgetsLoader with enabled: false"; fi
  grep -qiE 'color:[[:space:]]*"transparent"|opacity:' <<<"$back" && bad "the backdrop can be see-through" \
    || ok "nothing in the backdrop is see-through"
  # made at every lock: a leastBusy place or colText colour comes from the desktop's result while locked, at once
  abw=$(code "$qs/modules/caelestia/background/pcwidgets/AbstractBackgroundWidget.qml")
  grep -q 'GlobalStates.screenLocked ? WallpaperRegions.get(leastBusyRegionProc.command) : null' <<<"$abw" &&
    grep -q 'WallpaperRegions.put(leastBusyRegionProc.command, parsedContent)' <<<"$abw" &&
    [[ -f $qs/services/WallpaperRegions.qml ]] && ok "the lock's widgets reuse the desktop's placement and colour" \
    || bad "AbstractBackgroundWidget.qml doesn't reuse WallpaperRegions' results while locked"
else bad "modules/ii/lock/LockBackdrop.qml is missing"; fi

((fails == 0)) || { echo "lock-xray tests: $fails FAILED"; exit 1; }
echo "lock-xray tests: OK"

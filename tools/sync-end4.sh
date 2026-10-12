#!/usr/bin/env bash
# caelestia4: merge end-4 upstream (github.com/end-4/dots-hyprland) into this fork.
# Paths we removed on purpose (REMOVED below) would otherwise come back or stop the merge:
#  - upstream edits to a removed file  -> modify/delete conflict  -> resolved by keeping it removed
#  - upstream adds a file under a removed directory -> merges cleanly -> removed again after the merge
# Anything else that conflicts is left for you to resolve (the script stops and lists it).
# Usage: tools/sync-end4.sh        Author: git config of this repo (John La).
set -euo pipefail
cd "$(dirname "$0")/.."

REMOVED=(
  dots/.config/quickshell/ii/modules/waffle            # Waffle panel family (removed 2026-10-11)
  dots/.config/quickshell/ii/panelFamilies/WaffleFamily.qml
  dots/.config/quickshell/ii/modules/common/widgets/CalendarView.qml  # only used by Waffle
  # end-4's ii panel family (removed 2026-10-12): only the parts the Caelestia family reuses are kept
  dots/.config/quickshell/ii/panelFamilies/IllogicalImpulseFamily.qml
  dots/.config/quickshell/ii/modules/ii/bar                # tray files moved to modules/ii/lock (lock screen tray)
  dots/.config/quickshell/ii/modules/ii/verticalBar
  dots/.config/quickshell/ii/modules/ii/background
  dots/.config/quickshell/ii/modules/ii/dock
  dots/.config/quickshell/ii/modules/ii/mediaControls
  dots/.config/quickshell/ii/modules/ii/notificationPopup
  dots/.config/quickshell/ii/modules/ii/onScreenDisplay
  dots/.config/quickshell/ii/modules/ii/overview
  dots/.config/quickshell/ii/modules/ii/polkit
  dots/.config/quickshell/ii/modules/ii/screenCorners
  dots/.config/quickshell/ii/modules/ii/screenTranslator
  dots/.config/quickshell/ii/modules/ii/sessionScreen
  dots/.config/quickshell/ii/modules/ii/sidebarRight/bluetoothDevices   # sidebarRight: todo, pomodoro, volumeMixer kept
  dots/.config/quickshell/ii/modules/ii/sidebarRight/calendar
  dots/.config/quickshell/ii/modules/ii/sidebarRight/nightLight
  dots/.config/quickshell/ii/modules/ii/sidebarRight/notifications
  dots/.config/quickshell/ii/modules/ii/sidebarRight/quickToggles
  dots/.config/quickshell/ii/modules/ii/sidebarRight/wifiNetworks
  dots/.config/quickshell/ii/modules/ii/sidebarRight/BottomWidgetGroup.qml
  dots/.config/quickshell/ii/modules/ii/sidebarRight/CenterWidgetGroup.qml
  dots/.config/quickshell/ii/modules/ii/sidebarRight/QuickSliders.qml
  dots/.config/quickshell/ii/modules/ii/sidebarRight/SidebarRightContent.qml
  dots/.config/quickshell/ii/modules/ii/sidebarRight/SidebarRight.qml
)
is_removed() { local p; for p in "${REMOVED[@]}"; do [[ "$1" == "$p" || "$1" == "$p"/* ]] && return 0; done; return 1; }
GIT=(git -c user.name="John La" -c user.email=john.pla1998@gmail.com)

git diff --quiet && git diff --cached --quiet || { echo "working tree not clean" >&2; exit 1; }
git fetch -q upstream
echo "upstream commits to merge: $(git rev-list --count HEAD..upstream/main)"

if ! "${GIT[@]}" merge --no-edit upstream/main; then
  while IFS= read -r f; do
    is_removed "$f" && git rm -q --ignore-unmatch -- "$f" && echo "kept removed: $f"
  done < <(git diff --name-only --diff-filter=U)
  if [[ -n "$(git diff --name-only --diff-filter=U)" ]]; then
    echo "conflicts left to resolve:"; git diff --name-only --diff-filter=U; exit 1
  fi
  "${GIT[@]}" commit --no-edit -q
fi

# Files upstream added under removed paths
for p in "${REMOVED[@]}"; do
  if [[ -e "$p" ]]; then git rm -rq -- "$p"; echo "removed again: $p"; fi
done
git diff --cached --quiet || "${GIT[@]}" commit -qm "sync-end4: keep removed paths removed"
echo "done: $(git log -1 --format='%h %s')"

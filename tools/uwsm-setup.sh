#!/usr/bin/env bash
# caelestia4: set up the uwsm-managed Hyprland session ("Hyprland (uwsm-managed)" at the login screen).
# Idempotent; run again after pulling. Needs: sudo pacman -S --needed uwsm  (provides uwsm + uwsm-app).
#
#  - env:   dots/.config/uwsm/env-hyprland -> ~/.config/uwsm/ (and dots-extra/uwsm/env-hyprland.d/* if missing)
#  - units: dots/.config/systemd/user/caelestia4-* -> ~/.config/systemd/user/, enabled for
#           wayland-session@hyprland.desktop.target (Hyprland session only; Plasma never starts them)
#  - app-graphical.slice drop-in: systemd-oomd kills the single app scope under sustained memory pressure
#  - packaged units wanted by that target too: hypridle, plasma-kwallet-pam (KWallet unlock), ydotool
#  - XDG autostart masked for this compositor only: with XDG_CURRENT_DESKTOP=Hyprland:KDE it would start
#    Plasma's OnlyShowIn=KDE entries (plasmashell, powerdevil, kglobalacceld, polkit-kde-agent, …)
# The plain "Hyprland" session keeps working as before (the config checks CAELESTIA4_UWSM).
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET=wayland-session@hyprland.desktop.target
say() { printf '\033[1;34m::\033[0m %s\n' "$*"; }

command -v uwsm >/dev/null && command -v uwsm-app >/dev/null || { echo "uwsm not installed: sudo pacman -S --needed uwsm" >&2; exit 1; }

# env
mkdir -p "$CFG/uwsm/env-hyprland.d"
install -m644 "$REPO/dots/.config/uwsm/env-hyprland" "$CFG/uwsm/env-hyprland"
say "installed $CFG/uwsm/env-hyprland"
for f in "$REPO"/dots-extra/uwsm/env-hyprland.d/*; do
  dst="$CFG/uwsm/env-hyprland.d/$(basename "$f")"
  [[ -e "$dst" ]] && say "kept $dst (machine-specific, not overwritten)" || { install -m644 "$f" "$dst"; say "installed $dst"; }
done

# units
mkdir -p "$CFG/systemd/user"
units=()
for f in "$REPO"/dots/.config/systemd/user/caelestia4-*; do
  install -m644 "$f" "$CFG/systemd/user/$(basename "$f")"
  units+=("$(basename "$f")")
done
# slice drop-ins (systemd-oomd per-app kill)
for d in "$REPO"/dots/.config/systemd/user/*.slice.d; do
  mkdir -p "$CFG/systemd/user/$(basename "$d")"
  install -m644 "$d"/*.conf "$CFG/systemd/user/$(basename "$d")/"
  say "installed $(basename "$d") drop-in"
done
systemctl --user daemon-reload

enable=(caelestia4-shell.service caelestia4-cliphist@text.service caelestia4-cliphist@image.service caelestia4-geoclue-agent.service)
command -v fcitx5 >/dev/null && enable+=(caelestia4-fcitx5.service)
command -v easyeffects >/dev/null && enable+=(caelestia4-easyeffects.service)
command -v kdeconnectd >/dev/null && enable+=(caelestia4-kdeconnectd.service caelestia4-kdeconnect-indicator.service)
systemctl --user enable "${enable[@]}"
say "enabled for $TARGET: ${enable[*]}"

packaged=()
for u in hypridle.service plasma-kwallet-pam.service ydotool.service; do
  systemctl --user cat "$u" >/dev/null 2>&1 && packaged+=("$u")
done
((${#packaged[@]})) && systemctl --user add-wants "$TARGET" "${packaged[@]}" && say "wanted by $TARGET: ${packaged[*]}"

systemctl --user mask wayland-session-xdg-autostart@hyprland.desktop.target >/dev/null
say "XDG autostart masked for Hyprland (Plasma unaffected)"

say "done. Log out and pick \"Hyprland (uwsm-managed)\" at the login screen."
say "check: systemctl --user list-dependencies $TARGET"

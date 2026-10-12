#!/usr/bin/env bash
# caelestia4: set up the uwsm-managed Hyprland session ("Hyprland (uwsm-managed)" at the login screen).
# Idempotent; run again after pulling. Needs: sudo pacman -S --needed uwsm  (provides uwsm + uwsm-app).
#
#  - env:   dots/.config/uwsm/env-hyprland -> ~/.config/uwsm/ (and dots-extra/uwsm/env-hyprland.d/* if missing)
#  - units: dots/.config/systemd/user/caelestia4-* -> ~/.config/systemd/user/, WantedBy=graphical-session.target
#           with ConditionEnvironment=CAELESTIA4_UWSM=1 (set only by the uwsm Hyprland env, so Plasma skips them).
#           Not wanted by wayland-session@hyprland.desktop.target: a target is ordered after what it wants, uwsm
#           orders graphical-session.target after that target, and the units are After=graphical-session.target,
#           so systemd found an ordering cycle and dropped every start job (shell, hypridle, …) at login.
#  - app-graphical.slice drop-in: systemd-oomd kills the single app scope under sustained memory pressure
#  - packaged units (hypridle, plasma-kwallet-pam, ydotool) are started by hypr/hyprland/execs.lua under uwsm; they
#    can't take the condition (Plasma uses plasma-kwallet-pam too)
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

# default terminal for uwsm -T (xdg-terminal-exec spec); a user choice, so only if missing
[[ -e "$CFG/xdg-terminals.list" ]] && say "kept $CFG/xdg-terminals.list" || { install -m644 "$REPO/dots/.config/xdg-terminals.list" "$CFG/xdg-terminals.list"; say "installed $CFG/xdg-terminals.list"; }

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
# reenable: drops links from older setups (they were wanted by $TARGET, which made an ordering cycle)
systemctl --user reenable "${enable[@]}" 2>/dev/null
say "enabled for graphical-session.target (uwsm Hyprland only): ${enable[*]}"

# older setups also added packaged units to $TARGET; remove those links (same cycle)
for u in hypridle.service plasma-kwallet-pam.service ydotool.service; do
  rm -f "$CFG/systemd/user/$TARGET.wants/$u"
done
rmdir "$CFG/systemd/user/$TARGET.wants" 2>/dev/null || true
systemctl --user daemon-reload

# Private copy of hyprland.desktop for uwsm ("uwsm start … hyprland.desktop" looks in ~/.local/share first). The login
# screen (Plasma Login Manager, its own user) lists every file in /usr/share/wayland-sessions and ignores NoDisplay/
# Hidden, so hiding the plain "Hyprland" entry means removing the system copy; this one keeps uwsm working.
mkdir -p "$HOME/.local/share/wayland-sessions"
[[ -e "$HOME/.local/share/wayland-sessions/hyprland.desktop" ]] || install -m644 "$REPO/dots-extra/uwsm/hyprland.desktop" "$HOME/.local/share/wayland-sessions/hyprland.desktop"
say "uwsm compositor entry: ~/.local/share/wayland-sessions/hyprland.desktop"
if [[ -e /usr/share/wayland-sessions/hyprland.desktop ]]; then
  say "to hide the plain \"Hyprland\" login entry (once):"
  say "  sudo sed -i 's|^#NoExtract *=.*|NoExtract   = usr/share/wayland-sessions/hyprland.desktop|' /etc/pacman.conf"
  say "  sudo rm /usr/share/wayland-sessions/hyprland.desktop"
fi

systemctl --user mask wayland-session-xdg-autostart@hyprland.desktop.target >/dev/null
say "XDG autostart masked for Hyprland (Plasma unaffected)"

say "done. Log out and pick \"Hyprland (uwsm-managed)\" at the login screen."
say "check: systemctl --user list-dependencies graphical-session.target | grep caelestia4"

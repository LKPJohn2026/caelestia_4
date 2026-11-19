#!/usr/bin/env bash
# caelestia4: where your keys live, KWallet or gnome-keyring. Run as your user.
#
# Apps that keep a key of their own (Chromium-based browsers, Electron apps, python-keyring) can each use either one,
# found on any install from the desktop entries; their key moves with them (tools/keyring-switch.py):
#   tools/keyring-switch.sh status [APP...]               each app, where its store is set, its key in each store
#   tools/keyring-switch.sh set gnome|kwallet APP...      move these apps; --all for every app with a key,
#                                                         --dry-run to see the plan first
# Then quit the moved apps fully (tray icon too) and start them again.
#
# Everything else (gh, Zed, the shell's API keys, libsecret apps, Flatpak's Secret portal) uses whoever serves
# org.freedesktop.secrets. Moving that from KWallet to gnome-keyring, KWallet left as it is:
#   tools/keyring-switch.sh prepare   KWallet's Secret Service off (kwalletrc), gnome-keyring unmasked, the Secret
#                                     portal on gnome-keyring. Then log out and in: PAM creates gnome-keyring's
#                                     login keyring with your login password and it serves org.freedesktop.secrets.
#   tools/keyring-switch.sh finish    every KWallet entry into the login keyring (tools/kwallet-to-keyring.py
#                                     --write, each one read back), then every app with a key onto gnome-keyring.
# Back to KWallet: the login screen's PAM starts gnome-keyring at each login (pam_gnome_keyring in /etc/pam.d/greetd),
# so it takes org.freedesktop.secrets first; that needs root, and the apps above can use KWallet without it.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib-require-dot-config.sh"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
say() { printf '\e[1;34m::\e[0m %s\n' "$*"; }
owner() { local pid; pid=$(busctl --user status "$1" 2>/dev/null | sed -n 's/^PID=//p'); [[ -n "$pid" ]] && cat "/proc/$pid/comm" 2>/dev/null; }
[[ "$(id -u)" -ne 0 ]] || { echo "Run as your user, not root." >&2; exit 1; }
PORTALS="$CFG/xdg-desktop-portal/hyprland-portals.conf"
LOCAL_ENV="$CFG/uwsm/env-hyprland.d/caelestia4-local.sh"

prepare() {
  command -v gnome-keyring-daemon >/dev/null || { echo "install gnome-keyring first: sudo pacman -S gnome-keyring" >&2; exit 1; }
  kwriteconfig6 --file kwalletrc --group org.freedesktop.secrets --key apiEnabled false
  say "KWallet: Secret Service API off (kwalletrc [org.freedesktop.secrets] apiEnabled=false); its own API stays"
  systemctl --user unmask gnome-keyring-daemon.socket gnome-keyring-daemon.service >/dev/null 2>&1 || true
  systemctl --user enable gnome-keyring-daemon.socket >/dev/null 2>&1 || true
  say "gnome-keyring: unmasked, socket enabled (PAM starts and unlocks it at login)"
  if [[ -f "$PORTALS" ]]; then
    sed -i -e 's/^org\.freedesktop\.impl\.portal\.Secret = kwallet$/org.freedesktop.impl.portal.Secret = gnome-keyring/' \
      -e 's/^# caelestia4: app secrets (Brave\/Chromium\/Electron "safe storage") go to KWallet.*$/# caelestia4: the Secret portal (Flatpak apps, Chromium'"'"'s portal key) on gnome-keyring/' "$PORTALS"
    say "Secret portal: $(sed -n 's/^org\.freedesktop\.impl\.portal\.Secret = //p' "$PORTALS")"
  fi
  cat <<'EOF'

Now log out and in (the login screen's PAM creates the "login" keyring with your password), then run:
  tools/keyring-switch.sh finish
Until then gh, Zed, the Assistant and Python keyring may say they're signed out: their keys are still in KWallet.
The browsers and Electron apps set to KWallet keep using it; "finish" moves them too.
EOF
}

finish() {
  local who; who=$(owner org.freedesktop.secrets || true)
  [[ "$who" == gnome-keyring-d ]] || { echo "org.freedesktop.secrets is served by ${who:-nobody}, not gnome-keyring: log out and in after 'prepare'" >&2; exit 1; }
  [[ -n "$(owner org.kde.kwalletd6 || true)" ]] || busctl --user call org.kde.kwalletd6 /modules/kwalletd6 org.kde.KWallet isEnabled >/dev/null
  python3 "$REPO/tools/kwallet-to-keyring.py" --write
  say "keys copied; now every app with a key of its own onto gnome-keyring"
  python3 "$REPO/tools/keyring-switch.py" set gnome --all
  # An unflagged app picks KWallet when the desktop's name has KDE in it: only your own env file
  if [[ -f "$LOCAL_ENV" ]] && grep -q '^export XDG_CURRENT_DESKTOP=Hyprland:KDE$' "$LOCAL_ENV"; then
    sed -i 's/^export XDG_CURRENT_DESKTOP=Hyprland:KDE$/export XDG_CURRENT_DESKTOP=Hyprland/' "$LOCAL_ENV"
    say "XDG_CURRENT_DESKTOP=Hyprland from the next login"
  fi
  cat <<'EOF'

Quit the apps above, then log out and in. Check: your browser's saved passwords and that you're still signed in to
sites; the Electron apps signed in; gh auth status; Zed's accounts; the Assistant's API key; Python keyring.
KWallet still has everything: tools/keyring-switch.sh set kwallet --all puts the apps back on it.
EOF
}

case "${1:-}" in
  prepare) prepare ;;
  finish) finish ;;
  status|set) exec python3 "$REPO/tools/keyring-switch.py" "$@" ;;
  *) sed -n '2,20p' "$0" >&2; exit 1 ;;
esac

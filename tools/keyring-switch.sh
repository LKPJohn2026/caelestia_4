#!/usr/bin/env bash
# caelestia4: move the Secret Service from KWallet to gnome-keyring (docs/dev/kde-removal.md, phase 3). Run as your
# user. KWallet stays the source until the end: nothing is removed from it.
#   tools/keyring-switch.sh prepare   KWallet's Secret Service off (kwalletrc), gnome-keyring unmasked, the Secret
#                                     portal on gnome-keyring. Then log out and in: PAM creates gnome-keyring's
#                                     login keyring with your login password and it serves org.freedesktop.secrets.
#                                     Brave / Claude / Vesktop keep reading KWallet directly until "finish".
#   tools/keyring-switch.sh finish    every KWallet entry into the login keyring (tools/kwallet-to-keyring.py
#                                     --write, each one read back), then Brave, Vesktop and Claude on
#                                     --password-store=gnome-libsecret and XDG_CURRENT_DESKTOP=Hyprland. Then quit
#                                     them and log out and in.
# Chromium / Electron pick the key store from XDG_CURRENT_DESKTOP, and an unknown desktop (Hyprland) gets the
# unencrypted "basic" store, so the apps with a key are told explicitly.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
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
  sed -i 's/^org\.freedesktop\.impl\.portal\.Secret = kwallet$/org.freedesktop.impl.portal.Secret = gnome-keyring/' "$PORTALS"
  say "Secret portal: $(sed -n 's/^org\.freedesktop\.impl\.portal\.Secret = //p' "$PORTALS")"
  cat <<'EOF'

Now log out and in (the login screen's PAM creates the "login" keyring with your password), then run:
  tools/keyring-switch.sh finish
Until then gh, Zed, the Assistant and Python keyring may say they're signed out: their keys are still in KWallet.
EOF
}

finish() {
  local who; who=$(owner org.freedesktop.secrets || true)
  [[ "$who" == gnome-keyring-d ]] || { echo "org.freedesktop.secrets is served by ${who:-nobody}, not gnome-keyring: log out and in after 'prepare'" >&2; exit 1; }
  [[ -n "$(owner org.kde.kwalletd6 || true)" ]] || busctl --user call org.kde.kwalletd6 /modules/kwalletd6 org.kde.KWallet isEnabled >/dev/null
  python3 "$REPO/tools/kwallet-to-keyring.py" --write
  say "keys copied; now the apps that had one in KWallet read gnome-keyring"

  local f
  for f in "$CFG/brave-flags.conf" "$CFG/brave-origin-flags.conf"; do
    [[ -f "$f" ]] || continue
    sed -i -e 's/^--password-store=kwallet6$/--password-store=gnome-libsecret/' \
      -e 's/^# caelestia4: same KWallet key in Plasma and Hyprland.*$/# caelestia4: keys in gnome-keyring (libsecret); an unknown desktop would get the unencrypted "basic" store/' "$f"
    grep -q '^--password-store=gnome-libsecret$' "$f" || printf '# caelestia4: keys in gnome-keyring (libsecret)\n--password-store=gnome-libsecret\n' >> "$f"
    say "$(basename "$f"): --password-store=gnome-libsecret"
  done
  if command -v vesktop >/dev/null; then
    f="$CFG/vesktop-flags.conf"
    grep -qs '^--password-store=gnome-libsecret$' "$f" || printf '# caelestia4: keys in gnome-keyring (libsecret)\n--password-store=gnome-libsecret\n' >> "$f"
    say "vesktop-flags.conf: --password-store=gnome-libsecret"
  fi
  # Claude has no flags file: its launcher (a copy in ~/.local/share/applications, which wins over the system one)
  f="$HOME/.local/share/applications/com.anthropic.Claude.desktop"
  [[ -f "$f" ]] || { [[ -f /usr/share/applications/com.anthropic.Claude.desktop ]] && cp /usr/share/applications/com.anthropic.Claude.desktop "$f"; }
  if [[ -f "$f" ]]; then
    sed -i 's|^Exec=claude-desktop \(--password-store=gnome-libsecret \)\?|Exec=claude-desktop --password-store=gnome-libsecret |' "$f"
    say "Claude's launcher: --password-store=gnome-libsecret ($(grep -c 'password-store=gnome-libsecret' "$f") Exec lines)"
  fi

  for f in "$LOCAL_ENV" "$REPO/dots-extra/uwsm/env-hyprland.d/caelestia4-local.sh"; do
    [[ -f "$f" ]] && sed -i 's/^export XDG_CURRENT_DESKTOP=Hyprland:KDE$/export XDG_CURRENT_DESKTOP=Hyprland/' "$f"
  done
  say "XDG_CURRENT_DESKTOP=Hyprland from the next login"
  cat <<'EOF'

Quit Brave, Claude and Vesktop, then log out and in. Check: Brave's saved passwords and that you're still signed in
to sites; Claude signed in; gh auth status; Zed's accounts; the Assistant's API key; Python keyring (GEMINI_API_KEY).
Undo (KWallet still has everything): kwriteconfig6 --file kwalletrc --group org.freedesktop.secrets --key apiEnabled true,
put --password-store=kwallet6 back and XDG_CURRENT_DESKTOP=Hyprland:KDE, log out and in.
EOF
}

case "${1:-}" in
  prepare) prepare ;;
  finish) finish ;;
  *) sed -n '2,13p' "$0" >&2; exit 1 ;;
esac

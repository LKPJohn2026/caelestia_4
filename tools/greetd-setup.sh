#!/usr/bin/env bash
# caelestia4: set up greetd + ReGreet as the login screen (Plasma's login manager goes with Plasma).
# Run as your user, not root: it reads your session's monitors, scheme, wallpaper
# and keyboard layout, builds the files, checks the greeter's Hyprland config, then asks for sudo to install them:
#   /etc/greetd/config.toml       greetd: Hyprland (as "greeter") with ReGreet in it
#   /etc/greetd/hyprland.lua      that Hyprland: your monitors and scale, no logo / news / animations
#   /etc/greetd/regreet.toml      ReGreet: adw-gtk3, Breeze icons, Bibata cursor, Google Sans Flex, your locale's clock
#   /etc/greetd/regreet.css       Caelestia's style (dots-extra/greetd/regreet.css.in) in the scheme's colours
#   /etc/greetd/background.*      a copy of the wallpaper (the greeter can't read your home folder)
#   /etc/pam.d/greetd             greetd's own + pam_gnome_keyring
#   /usr/local/share/fonts/caelestia4/  Google Sans Flex for every user (tools/fonts-install.sh)
# It doesn't switch the login manager; it prints the command for that. Re-run it to refresh colours / wallpaper.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/dots-extra/greetd"
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib-require-dot-config.sh"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
say() { printf '\e[1;34m::\e[0m %s\n' "$*"; }
[[ "$(id -u)" -ne 0 ]] || { echo "Run as your user, not root." >&2; exit 1; }
for c in greetd regreet Hyprland; do command -v "$c" >/dev/null || { echo "$c is not installed (pacman -S greetd greetd-regreet)" >&2; exit 1; }; done
# The PAM file below is Arch's layout. Replacing it on anything else would lock everyone out of the login screen.
for f in /etc/pam.d/greetd /etc/pam.d/system-local-login /usr/lib/security/pam_securetty.so; do
  [[ -e "$f" ]] || { echo "$f is missing: this script's PAM file is for Arch. Nothing was changed." >&2; exit 1; }
done

# A new directory each run: a fixed name in /tmp could be made by another user first, and these files go to /etc as root;
# a reused one would also still hold a previous run's background.*
OUT=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/caelestia4-greetd.XXXXXX")
trap 'rm -r -- "$OUT"' EXIT # it holds a copy of the wallpaper, in RAM

# The files, from your session (tools/greetd-gen.py: every value escaped for its file, regreet.toml checked)
python3 -I "$REPO/tools/greetd-gen.py" "$SRC" "$OUT" "$CFG" "$STATE" "${AQ_DRM_DEVICES:-}"
cp "$SRC/pam-greetd" "$OUT/pam-greetd"

say "checking the greeter's Hyprland config"
Hyprland --verify-config -c "$OUT/hyprland.lua" 2>&1 | tail -3

say "installing (sudo)"
# A greetd set up by something else: its config kept next to it (this fork's has the greeter's Hyprland in it), under a
# new name when an earlier one was kept already
if [[ -e /etc/greetd/config.toml ]] && ! grep -qs '/etc/greetd/hyprland.lua' /etc/greetd/config.toml; then
  keep=/etc/greetd/config.toml.caelestia4-orig
  [[ -e "$keep" ]] && keep="$keep.$(date +%Y%m%d-%H%M%S)"
  sudo cp /etc/greetd/config.toml "$keep" && say "kept the old /etc/greetd/config.toml as $keep"
fi
sudo install -Dm644 "$OUT/config.toml" /etc/greetd/config.toml
sudo install -Dm644 "$OUT/hyprland.lua" /etc/greetd/hyprland.lua
sudo install -Dm644 "$OUT/regreet.toml" /etc/greetd/regreet.toml
sudo install -Dm644 "$OUT/regreet.css" /etc/greetd/regreet.css
for f in "$OUT"/background.*; do [[ -e "$f" ]] && sudo install -Dm644 "$f" "/etc/greetd/$(basename "$f")"; done
[[ -e /etc/pam.d/greetd.caelestia4-orig ]] || sudo cp /etc/pam.d/greetd /etc/pam.d/greetd.caelestia4-orig
sudo install -Dm644 "$OUT/pam-greetd" /etc/pam.d/greetd
say "installed /etc/greetd, /etc/pam.d/greetd (greetd's own kept as greetd.caelestia4-orig)"
"$REPO/tools/fonts-install.sh"

cat <<'EOF'

If greetd isn't the login screen yet (then reboot):
  sudo systemctl enable greetd.service
If the login screen doesn't come up: Ctrl+Alt+F2, log in, journalctl -b -u greetd and /var/log/regreet/log
EOF

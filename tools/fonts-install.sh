#!/usr/bin/env bash
# caelestia4: install every font this setup brings that no package provides, in one folder for every user
# (the login screen's greeter user too):
#   /usr/local/share/fonts/caelestia4/google-sans-flex/  Caelestia's UI font (the shell, hyprlock, ReGreet)
#   /usr/local/share/fonts/caelestia4/caveat/            end4-pC presets' desktop text (powder, ahri_v2, ichika_v2)
#   /usr/local/share/fonts/caelestia4/pacifico/          end4-pC presets' desktop text (Mustang)
# Each folder keeps its licence (OFL). Fonts from packages stay in /usr/share/fonts, where pacman keeps them.
# Run as your user, not root: it asks for sudo to install, then removes the old per-user copy in
# ~/.local/share/fonts/caelestia4 (the same Google Sans Flex, found twice). Re-run it after a font is added.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST=/usr/local/share/fonts/caelestia4
OLD="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/caelestia4"
say() { printf '\e[1;34m::\e[0m %s\n' "$*"; }
[[ "$(id -u)" -ne 0 ]] || { echo "Run as your user, not root." >&2; exit 1; }

# folder name -> source folder (the shell keeps its own copy of Google Sans Flex, which it loads itself)
declare -A FONTS=(
    [google-sans-flex]="$REPO/dots/.config/quickshell/ii/modules/caelestia/assets/google-sans-flex"
    [caveat]="$REPO/system/fonts/caveat"
    [pacifico]="$REPO/system/fonts/pacifico"
)

# fonts installed loose in $DEST before it had a folder per font
sudo find "$DEST" -maxdepth 1 -type f -delete 2>/dev/null || true
for name in "${!FONTS[@]}"; do
    sudo install -Dm644 -t "$DEST/$name" "${FONTS[$name]}"/*
    say "installed $name to $DEST/$name"
done
sudo fc-cache -f /usr/local/share/fonts >/dev/null

if [[ -d "$OLD" ]]; then
    rm -r "$OLD"
    rmdir --ignore-fail-on-non-empty "$(dirname "$OLD")"
    fc-cache -f >/dev/null
    say "removed the old copy in $OLD"
fi
fc-list : family file | grep -F "$DEST/" | sed 's|^|   |'

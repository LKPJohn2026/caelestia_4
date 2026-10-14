#!/usr/bin/env bash
# Install caelestia_4 as a Hyprland session for the CURRENT user on an account that also uses Plasma.
# No sudo. Never runs end-4's installer (it would overwrite kdeglobals, fish, app style, GTK, …).
# - Backs up every path it replaces to ~/.local/state/caelestia4/backup-<time>/
# - Never overwrites existing user configs for fuzzel/kitty/foot/wlogout/portals (copies only if missing/empty)
# - Keeps ~/.config/hypr/custom/, monitors.lua, workspaces.lua on re-runs
# - Creates ~/.config/caelestia4/shared-desktop: tells patched end-4 code to leave Plasma's settings alone
#   (no gnome-keyring start, no gsettings gtk-theme, no kdeglobals, no VS Code settings.json)
# Re-run safely to update after a `git pull` (tools/stage-for-test.sh is only for test users).
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
BK="$STATE/caelestia4/backup-$(date +%Y%m%d-%H%M%S)"
DOTS="$REPO/dots/.config"
say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!!\033[0m %s\n' "$*"; }

# ---- preflight ----
[[ "$(id -u)" -ne 0 ]] || { echo "Run as your user, not root." >&2; exit 1; }
for p in hyprland caelestia4-quickshell qt6-m3shapes-git illogical-impulse-kde illogical-impulse-widgets gpu-screen-recorder; do
  pacman -Q "$p" >/dev/null 2>&1 || warn "package $p not installed (install it first; see docs/install.md)"
done
[[ "$(systemctl --user is-enabled gnome-keyring-daemon.socket 2>/dev/null)" == masked ]] \
  || warn "gnome-keyring socket is not masked for this user (see docs/phase0.md: KWallet must own org.freedesktop.secrets)"
"$REPO/tools/lint-caelestia.sh"

backup() { # backup <path>
  local p="$1"; [[ -e "$p" ]] || return 0
  local rel="${p#$HOME/}"; mkdir -p "$BK/$(dirname "$rel")"; cp -a "$p" "$BK/$rel"
}
copy_if_missing() { # copy_if_missing <src> <dst>: only if dst missing or an empty dir
  local src="$1" dst="$2"
  if [[ ! -e "$dst" ]] || { [[ -d "$dst" ]] && [[ -z "$(ls -A "$dst")" ]]; }; then
    # caelestia4: copy the *contents* (cp -a src dst into an existing empty dir nested it: ~/.config/kitty/kitty/)
    mkdir -p "$dst"; cp -a "$src/." "$dst/"; say "installed $dst"
  else
    say "kept existing $dst"
  fi
}

# ---- Caelestia plugin (user-local) ----
[[ -d "$HOME/.local/lib/qt6/qml/Caelestia" ]] || "$REPO/tools/build-caelestia-plugin.sh"

# ---- marker: shared Plasma account ----
mkdir -p "$CFG/caelestia4"; touch "$CFG/caelestia4/shared-desktop"

# ---- Quickshell config (ours) ----
backup "$CFG/quickshell/ii"
mkdir -p "$CFG/quickshell"
rsync -a --delete --exclude '.git' "$DOTS/quickshell/ii/" "$CFG/quickshell/ii/"
# caelestia4: the shell doesn't hot-reload (Quickshell.watchFiles = false, see shell.qml): restart it to pick up
# the new files, if it's running as a unit
systemctl --user try-restart caelestia4-shell.service 2>/dev/null || true
# caelestia4: Caelestia's app themes (btop / fastfetch / cava configs, Zen userChrome, the Caelestia extension in
# Cursor / VS Code / VSCodium); never replaces a file it didn't create. Colours then follow every scheme change.
python3 "$CFG/quickshell/ii/modules/caelestia/utils/scripts/apptheme.py" setup || warn "app themes setup failed"

# end-4 Python venv (end-4's installer makes it; ours didn't): terminal colours from the wallpaper
# (generate_colors_material.py), screen translator sign-in (google-auth), image regions / text colours (opencv).
# Python 3.12 as end-4 pins it (uv fetches it); locked deps from sdata/uv/requirements.txt.
VENV="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv"
if [[ -x "$VENV/bin/python" ]]; then
  say "kept existing $VENV"
elif command -v uv >/dev/null; then
  UV_NO_MODIFY_PATH=1 uv venv --prompt .venv "$VENV" -p 3.12 \
    && VIRTUAL_ENV="$VENV" uv pip install -r "$REPO/sdata/uv/requirements.txt" && say "created $VENV"
else
  warn "uv not installed: end-4's Python venv not created (sudo pacman -S uv, then re-run)"
fi
say "installed $CFG/quickshell/ii"

# ---- Hyprland config (end-4 + caelestia4 patches); keep user files on re-runs ----
backup "$CFG/hypr"
mkdir -p "$CFG/hypr"
rsync -a --delete --exclude 'custom/' --exclude 'monitors.lua' --exclude 'workspaces.lua' --exclude 'hyprland/shellOverrides/main.lua' \
      --exclude 'hyprland/colors.lua' --exclude 'hyprlock/colors.conf' "$DOTS/hypr/" "$CFG/hypr/"
[[ -f "$CFG/hypr/hyprland/colors.lua" ]] || cp "$DOTS/hypr/hyprland/colors.lua" "$CFG/hypr/hyprland/colors.lua"
# caelestia4: settings-app Hyprland options live here (written by the shell); never overwrite them
[[ -f "$CFG/hypr/hyprland/shellOverrides/main.lua" ]] || { mkdir -p "$CFG/hypr/hyprland/shellOverrides"; cp "$DOTS/hypr/hyprland/shellOverrides/main.lua" "$CFG/hypr/hyprland/shellOverrides/main.lua"; }
[[ -f "$CFG/hypr/hyprlock/colors.conf" ]] || cp "$DOTS/hypr/hyprlock/colors.conf" "$CFG/hypr/hyprlock/colors.conf"
[[ -d "$CFG/hypr/custom" ]] || cp -a "$DOTS/hypr/custom" "$CFG/hypr/custom"
ENV="$CFG/hypr/custom/env.lua"
if ! grep -q 'QML_IMPORT_PATH' "$ENV" 2>/dev/null; then
  cat >> "$ENV" <<'LUA'

-- caelestia4: user-local Caelestia QML plugin, visible to Quickshell in this session only
hl.env("QML_IMPORT_PATH", os.getenv("HOME") .. "/.local/lib/qt6/qml")
LUA
fi
if ! grep -q 'AQ_DRM_DEVICES' "$ENV" 2>/dev/null; then
  if [[ -e /dev/dri/nvidia-dgpu ]]; then gpu=/dev/dri/nvidia-dgpu
  else gpu=/dev/dri/card1; warn "udev rule not installed; using $gpu (may change between boots; see system/udev/)"; fi
  cat >> "$ENV" <<LUA

-- caelestia4: render on the GPU that drives the monitor (RTX 5090)
hl.env("AQ_DRM_DEVICES", "$gpu")
LUA
fi
if [[ ! -f "$CFG/hypr/monitors.lua" ]]; then
  cat > "$CFG/hypr/monitors.lua" <<'LUA'
-- caelestia4: Samsung 57" (SAM7475) on DP-2
hl.monitor({
    output = "DP-2",
    mode = "7680x2160@240",
    position = "0x0",
    scale = 1.5
})
LUA
  say "created $CFG/hypr/monitors.lua"
fi

# ---- matugen (colour generation) without the GTK templates (GTK css is shared with Plasma) ----
backup "$CFG/matugen"
rsync -a --delete "$DOTS/matugen/" "$CFG/matugen/"
# caelestia4: Caelestia's UI font for hyprlock (the shell loads its bundled copy itself; hyprlock needs it installed)
mkdir -p "$HOME/.local/share/fonts/caelestia4"
cp "$DOTS/quickshell/ii/modules/caelestia/assets/google-sans-flex/"* "$HOME/.local/share/fonts/caelestia4/"
fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
say "installed Google Sans Flex to ~/.local/share/fonts/caelestia4 (hyprlock)"
python3 - "$CFG/matugen/config.toml" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
s = re.sub(r'\[templates\.gtk[34]\]\n(?:[^\[\n].*\n?)*', '', s)
p.write_text("# caelestia4: gtk3/gtk4 templates removed (gtk.css is shared with Plasma)\n" + s)
PY
say "installed $CFG/matugen (no GTK templates)"

# ---- small app configs: only if the user has none ----
for d in fuzzel kitty foot wlogout; do copy_if_missing "$DOTS/$d" "$CFG/$d"; done
copy_if_missing "$DOTS/xdg-desktop-portal/hyprland-portals.conf" "$CFG/xdg-desktop-portal/hyprland-portals.conf"
copy_if_missing "$DOTS/caelestia/shell.json" "$CFG/caelestia/shell.json" # caelestia4: bar speaker icon on (opens the audio popout / per-app mixer)
mkdir -p "$HOME/.local/share/icons"; cp -n "$REPO/dots/.local/share/icons/illogical-impulse.svg" "$HOME/.local/share/icons/" 2>/dev/null || true

# ---- end-4 shell config: start in the caelestia family; never auto-kill KDE daemons ----
II="$CFG/illogical-impulse/config.json"
if [[ ! -f "$II" ]]; then
  mkdir -p "$(dirname "$II")"
  # lock.useHyprlock: hyprlock survives the G95NC dropping off DP 2.1 on wake (the in-shell lock can lose its surface)
  printf '{\n  "panelFamily": "caelestia",\n  "conflictKiller": { "autoKillTrays": false, "autoKillNotificationDaemons": false },\n  "lock": { "useHyprlock": true }\n}\n' > "$II"
  say "created $II (panelFamily: caelestia)"
fi

# ---- dirs caelestia-cli would normally create ----
mkdir -p "$STATE/caelestia" "${XDG_CACHE_HOME:-$HOME/.cache}/caelestia/imagecache/notifs"

[[ -d "$BK" ]] && say "backups: $BK" || say "nothing needed backing up"
say "done. Log out, pick the 'Hyprland' session on the login screen. Ctrl+Super+P cycles panel families."

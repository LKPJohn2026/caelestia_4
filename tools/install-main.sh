#!/usr/bin/env bash
# Install caelestia_4 as a Hyprland session for the CURRENT user on an account that also uses Plasma.
# No sudo. Never runs end-4's installer (it would overwrite kdeglobals, fish, app style, GTK, …).
# - Backs up every path it replaces to ~/.local/state/caelestia4/backup-<time>/
# - Never overwrites existing user configs for fuzzel/kitty/foot/wlogout/portals (copies only if missing/empty)
# - Keeps ~/.config/hypr/custom/, monitors.lua, workspaces.lua on re-runs
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
# caelestia4: gnome-keyring is the Secret Service since the move off KWallet (docs/dev/kde-removal.md, phase 3)
[[ "$(systemctl --user is-enabled gnome-keyring-daemon.socket 2>/dev/null)" != masked ]] \
  || warn "gnome-keyring is masked for this user (from the KWallet days): tools/keyring-switch.sh prepare unmasks it"
"$REPO/tools/lint-caelestia.sh"

backup() { # backup <path>
  local p="$1"; [[ -e "$p" ]] || return 0
  local rel="${p#$HOME/}"; mkdir -p "$BK/$(dirname "$rel")"; cp -a "$p" "$BK/$rel"
}
copy_file_if_missing() { # copy_file_if_missing <src> <dst>: one file, only if dst doesn't exist
  if [[ -e "$2" ]]; then say "kept existing $2"; else mkdir -p "$(dirname "$2")"; cp "$1" "$2"; say "installed $2"; fi
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

# caelestia4: the shared-desktop marker (an account shared with Plasma) is gone with Plasma (docs/dev/kde-removal.md)
mkdir -p "$CFG/caelestia4"; rm -f "$CFG/caelestia4/shared-desktop"
printf '%s\n' "$REPO" > "$CFG/caelestia4/repo" # caelestia4: where this clone is (Nexus > Updates checks it for new commits)

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
# caelestia4: hypridle-timeouts.conf is generated from the settings app (Power & idle); --delete removed it, and then
# hypridle ran with no rules at all: never locked, never turned the screen off, never slept
rsync -a --delete --exclude 'custom/' --exclude 'monitors.lua' --exclude 'workspaces.lua' --exclude 'hyprland/shellOverrides/main.lua' --exclude 'hypridle-timeouts.conf' \
      --exclude 'hyprland/colors.lua' --exclude 'hyprlock/colors.conf' --exclude 'hyprlock/lockwall.conf' "$DOTS/hypr/" "$CFG/hypr/"
[[ -f "$CFG/hypr/hyprland/colors.lua" ]] || cp "$DOTS/hypr/hyprland/colors.lua" "$CFG/hypr/hyprland/colors.lua"
# caelestia4: settings-app Hyprland options live here (written by the shell); never overwrite them
[[ -f "$CFG/hypr/hyprland/shellOverrides/main.lua" ]] || { mkdir -p "$CFG/hypr/hyprland/shellOverrides"; cp "$DOTS/hypr/hyprland/shellOverrides/main.lua" "$CFG/hypr/hyprland/shellOverrides/main.lua"; }
[[ -f "$CFG/hypr/hyprlock/colors.conf" ]] || cp "$DOTS/hypr/hyprlock/colors.conf" "$CFG/hypr/hyprlock/colors.conf"
[[ -f "$CFG/hypr/hyprlock/lockwall.conf" ]] || cp "$DOTS/hypr/hyprlock/lockwall.conf" "$CFG/hypr/hyprlock/lockwall.conf"
[[ -d "$CFG/hypr/custom" ]] || cp -a "$DOTS/hypr/custom" "$CFG/hypr/custom"
# hypridle's timers: (re)create them from the saved settings when missing (5 / 10 / 15 min and lock before sleep by default)
if [[ ! -f "$CFG/hypr/hypridle-timeouts.conf" ]]; then
  read -r lockm offm sleepm lockb < <(jq -r '.caelestia.idle // {} | "\(.lockMinutes // 5) \(.screenOffMinutes // 10) \(.suspendMinutes // 0) \(.lockBeforeSleep // true)"' \
    "$CFG/illogical-impulse/config.json" 2>/dev/null || echo "5 10 15 true")
  "$CFG/quickshell/ii/scripts/caelestia4/hypridle-timeouts.sh" "${lockm:-5}" "${offm:-10}" "${sleepm:-15}" "${lockb:-true}" \
    && say "created $CFG/hypr/hypridle-timeouts.conf (idle: lock ${lockm}m, screen off ${offm}m, suspend ${sleepm}m)"
fi
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
-- caelestia4: Samsung 57" (SAM7475), by description: its connector name changes between boots (DP-2, DP-6)
hl.monitor({
    output = "desc:Samsung Electric Company Odyssey G95NC HNTX401477",
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
# caelestia4: fonts no package provides (Google Sans Flex for hyprlock, the presets' text fonts) are installed for
# every user by tools/fonts-install.sh, which needs sudo (the shell loads its bundled Google Sans Flex itself)
[[ -d /usr/local/share/fonts/caelestia4/caveat ]] ||
    warn "fonts not installed: run tools/fonts-install.sh (asks for sudo)"
python3 - "$CFG/matugen/config.toml" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
s = re.sub(r'\[templates\.gtk[34]\]\n(?:[^\[\n].*\n?)*', '', s)
p.write_text("# caelestia4: gtk3/gtk4 templates removed (gtk.css is caelestia-cli's, cli.json enableGtk)\n" + s)
PY
say "installed $CFG/matugen (no GTK templates)"

# ---- small app configs: only if the user has none ----
for d in fuzzel kitty foot wlogout; do copy_if_missing "$DOTS/$d" "$CFG/$d"; done
copy_file_if_missing "$DOTS/xdg-desktop-portal/hyprland-portals.conf" "$CFG/xdg-desktop-portal/hyprland-portals.conf"
# caelestia4: Open/Save dialogs moved from KDE to Wormhole, then the fallback and the KDE-only interfaces (Background,
# Clipboard, Usb, Wallpaper) off KDE's portal, which goes with Plasma; only the old defaults are changed
sed -i -e 's/^org\.freedesktop\.impl\.portal\.FileChooser = \(wormhole;\)\?kde$/org.freedesktop.impl.portal.FileChooser = wormhole;gtk/' \
    -e 's/^\(org\.freedesktop\.impl\.portal\.\(Background\|Clipboard\|Usb\|Wallpaper\)\) = kde$/\1 = none/' \
    "$CFG/xdg-desktop-portal/hyprland-portals.conf"
# and the KDE pins (Background, Clipboard, Usb, Wallpaper) added to an existing file, so Wormhole stays FileChooser-only
python3 - "$DOTS/xdg-desktop-portal/hyprland-portals.conf" "$CFG/xdg-desktop-portal/hyprland-portals.conf" <<'PY'
import sys
src, dst = sys.argv[1:]
have = {l.split("=")[0].strip() for l in open(dst) if "=" in l and not l.startswith("#")}
new = [l for l in open(src) if "=" in l and not l.startswith("#") and l.split("=")[0].strip() not in have]
if new:
    with open(dst, "a") as f:
        f.writelines(new)
PY
# caelestia4: Hyprland-session file associations (Thunar for folders); merged so the user's other entries stay
python3 - "$DOTS/hyprland-mimeapps.list" "$CFG/hyprland-mimeapps.list" <<'PY'
import sys, os
src, dst = sys.argv[1:]
want = [l.strip() for l in open(src) if "=" in l and not l.startswith("#")]
lines = open(dst).read().splitlines() if os.path.exists(dst) else []
# Earlier defaults of this file, replaced by the current ones (a value the user picked stays)
old = {"inode/directory=thunar.desktop"}
lines = [next((w for w in want if w.split("=")[0] == l.split("=")[0]), l) if l in old else l for l in lines]
if "[Default Applications]" not in lines:
    lines += ["[Default Applications]"]
i = lines.index("[Default Applications]") + 1
for entry in want:
    key = entry.split("=")[0]
    if not any(l.startswith(key + "=") for l in lines):
        lines.insert(i, entry)
open(dst, "w").write("\n".join(lines) + "\n")
PY
copy_file_if_missing "$DOTS/caelestia/shell.json" "$CFG/caelestia/shell.json" # caelestia4: bar speaker icon on (opens the audio popout / per-app mixer)
# Session menu: Caelestia's defaults are `logout` (a shell builtin, nothing to run) and `hibernate` (no such program):
# log out through uwsm and hibernate through systemd, unless the user set these
python3 - "$CFG/caelestia/shell.json" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
# caelestia4: Atlas as the shell's file manager (Caelestia's default is Thunar), unless the user picked one
changed = "explorer" not in d.setdefault("general", {}).setdefault("apps", {})
d["general"]["apps"].setdefault("explorer", ["atlas"])
cmds = d.setdefault("session", {}).setdefault("commands", {})
want = {"logout": ["uwsm", "stop"], "hibernate": ["systemctl", "hibernate"]}
if changed or any(k not in cmds for k in want):
    for k, v in want.items():
        cmds.setdefault(k, v)
    json.dump(d, open(p, "w"), indent=4)
PY
# caelestia-cli makes the colours (wallpaper or preset scheme); its postHook (scheme.py bridge) passes them to end-4.
# It themes GTK (gtk.css, dconf) and Qt (qtengine) too since Plasma's theming went (no htop / fuzzel / browser policy)
copy_file_if_missing "$DOTS/caelestia/cli.json" "$CFG/caelestia/cli.json"
# an older cli.json (GTK / Qt were Plasma's): turn them on once, with the Breeze icons (Caelestia's default is Papirus)
python3 - "$CFG/caelestia/cli.json" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
t = d.setdefault("theme", {})
if "iconThemeDark" not in t and "iconTheme" not in t:
    t.update(enableGtk=True, enableQt=True, iconThemeDark="breeze-dark", iconThemeLight="breeze")
    json.dump(d, open(p, "w"), indent=4)
PY
command -v caelestia >/dev/null || warn "caelestia-cli is not installed (yay -S caelestia-cli): colours fall back to end-4's matugen"
mkdir -p "$HOME/.local/share/icons"; cp -n "$REPO/dots/.local/share/icons/illogical-impulse.svg" "$HOME/.local/share/icons/" 2>/dev/null || true

# ---- end-4 shell config: start in the caelestia family; never auto-kill KDE daemons ----
II="$CFG/illogical-impulse/config.json"
if [[ ! -f "$II" ]]; then
  mkdir -p "$(dirname "$II")"
  # lock.useHyprlock: hyprlock survives the G95NC dropping off DP 2.1 on wake (the in-shell lock can lose its surface)
  printf '{\n  "panelFamily": "caelestia",\n  "conflictKiller": { "autoKillTrays": false, "autoKillNotificationDaemons": false },\n  "lock": { "useHyprlock": true }\n}\n' > "$II"
  say "created $II (panelFamily: caelestia)"
fi
# caelestia4: the task manager (session menu, Nexus > Apps) was Plasma's System Monitor: btop, unless the user set one
python3 - "$II" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
if d.get("apps", {}).get("taskManager") == "plasma-systemmonitor --page-name Processes":
    d["apps"]["taskManager"] = "kitty -1 btop"
    json.dump(d, open(p, "w"), indent=2)
PY

# ---- dirs caelestia-cli would normally create ----
mkdir -p "$STATE/caelestia" "${XDG_CACHE_HOME:-$HOME/.cache}/caelestia/imagecache/notifs"

[[ -d "$BK" ]] && say "backups: $BK" || say "nothing needed backing up"
say "done. Run tools/uwsm-setup.sh if you haven't, log out and pick 'Hyprland (uwsm-managed)' on the login screen."

#!/usr/bin/env bash
# Install caelestia_4's configs for the CURRENT user (./install.sh runs it after the packages; on its own it needs them
# installed already). No sudo. Never runs end-4's installer (it would overwrite kdeglobals, fish, app style, GTK, …).
# - Backs up every path it replaces to ~/.local/state/caelestia4/backup-<time>/
# - Never overwrites existing user configs for fuzzel/kitty/foot/wlogout/portals (copies only if missing/empty)
# - Keeps ~/.config/hypr/custom/, monitors.lua, workspaces.lua on re-runs
# Re-run safely to update after a `git pull` (tools/stage-for-test.sh is only for test users).
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib-require-dot-config.sh"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
BK="$STATE/caelestia4/backup-$(date +%Y%m%d-%H%M%S)"
DOTS="$REPO/dots/.config"
say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!!\033[0m %s\n' "$*"; }

# ---- preflight ----
[[ "$(id -u)" -ne 0 ]] || { echo "Run as your user, not root." >&2; exit 1; }
# These do the copying: without one, the script would stop half way through with the configs half replaced
for c in rsync jq git python3; do
  command -v "$c" >/dev/null || { echo "$c is missing (sudo pacman -S --needed $c), nothing was changed." >&2; exit 1; }
done
for p in hyprland caelestia4-quickshell caelestia4-qtengine caelestia4-wormhole qt6-m3shapes-git illogical-impulse-kde illogical-impulse-widgets illogical-impulse-caelestia4; do
  pacman -Q "$p" >/dev/null 2>&1 || warn "package $p not installed (install it first; see docs/install.md)"
done
# caelestia4: gnome-keyring is the Secret Service since the move off KWallet (docs/dev/kde-removal.md, phase 3)
[[ "$(systemctl --user is-enabled gnome-keyring-daemon.socket 2>/dev/null)" != masked ]] \
  || warn "gnome-keyring is masked for this user (from the KWallet days): tools/keyring-switch.sh prepare unmasks it"
# caelestia4: the shapes library is a git submodule, which a plain `git clone` leaves empty: the bar and the widgets
# wouldn't load. A pull can also move it to another version, which `git pull` alone doesn't check out: it follows then,
# but work of your own on top of the recorded version stays where it is.
SHAPES="dots/.config/quickshell/ii/modules/common/widgets/shapes"
shapes_status=$(git -C "$REPO" submodule status -- "$SHAPES" 2>/dev/null || true)
if [[ "$shapes_status" != " "* ]] && ! { [[ "$shapes_status" == "+"* ]] && git -C "$REPO/$SHAPES" merge-base --is-ancestor \
    "$(git -C "$REPO" rev-parse "HEAD:$SHAPES")" HEAD 2>/dev/null; }; then
  if git -C "$REPO" submodule update --init -- "$SHAPES" 2>/dev/null; then
    say "brought $SHAPES to this commit's version"
  else
    warn "the submodule $SHAPES couldn't be brought to this commit's version: run git submodule update --init"
  fi
fi
[[ -f "$REPO/$SHAPES/material-shapes.js" ]] || {
  echo "$SHAPES is empty, and the submodule couldn't be fetched: use a git clone (git clone --recursive), not a zip." >&2
  exit 1
}
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
# caelestia4: built again when its source changed (the QML that comes with a pull can need its new properties), when it
# was built for another Qt minor release (it uses Qt's private API), or when ./install.sh --rebuild asks
PLUGIN_STAMP="$HOME/.local/lib/qt6/qml/Caelestia/caelestia4-build.json"
PLUGIN_FAILED=0
qt_minor_of() { sed -nE 's/^([0-9]+\.[0-9]+).*/\1/p' <<<"$1"; }
plugin_qt=$(qt_minor_of "$(jq -r '.qt // ""' "$PLUGIN_STAMP" 2>/dev/null)")
qt_now=$(qt_minor_of "$(pacman -Q qt6-base 2>/dev/null | awk '{print $2}')")
if [[ ! -d "$HOME/.local/lib/qt6/qml/Caelestia" ]]; then
  "$REPO/tools/build-caelestia-plugin.sh"
elif [[ "${C4_REBUILD_PLUGIN:-}" == 1 || ( -n "$plugin_qt" && -n "$qt_now" && "$plugin_qt" != "$qt_now" ) ]]; then
  say "building the Caelestia plugin again (built for Qt ${plugin_qt:-?}, Qt ${qt_now:-?} here)"
  "$REPO/tools/build-caelestia-plugin.sh" || { PLUGIN_FAILED=1; warn "the Caelestia plugin wasn't rebuilt: the shell won't load it until it is (tools/build-caelestia-plugin.sh), so it isn't restarted"; }
elif [[ "$(jq -r '.source // ""' "$PLUGIN_STAMP" 2>/dev/null)" != "$("$REPO/tools/build-caelestia-plugin.sh" --source-id)" ]]; then
  say "the Caelestia plugin's source changed: building it"
  "$REPO/tools/build-caelestia-plugin.sh" || { PLUGIN_FAILED=1; warn "the Caelestia plugin wasn't rebuilt: the shell may miss what the new QML needs, so it isn't restarted"; }
fi

# caelestia4: the shared-desktop marker (an account shared with Plasma) is gone with Plasma (docs/dev/kde-removal.md)
mkdir -p "$CFG/caelestia4"; rm -f "$CFG/caelestia4/shared-desktop"
printf '%s\n' "$REPO" > "$CFG/caelestia4/repo" # caelestia4: where this clone is (Nexus > Updates checks it for new commits)

# caelestia4: kitty's include, matugen's outputs and a few scripts can only name ~/.local/state: with the state elsewhere,
# their folders there lead to it
if [[ "$(realpath -m -- "$STATE")" != "$(realpath -m -- "$HOME/.local/state")" ]]; then
  mkdir -p "$HOME/.local/state"
  for dir in quickshell caelestia; do
    if [[ -L "$HOME/.local/state/$dir" || ! -e "$HOME/.local/state/$dir" ]]; then
      mkdir -p "$STATE/$dir"
      ln -sfn "$STATE/$dir" "$HOME/.local/state/$dir"
    else
      warn "$HOME/.local/state/$dir is a real folder: move it to $STATE/$dir, then run this again (terminal colours would stay behind)"
    fi
  done
else
  # A link left by such an install, to a folder that's gone, would stop this script further down
  for dir in quickshell caelestia; do
    if [[ -L "$HOME/.local/state/$dir" && ! -e "$HOME/.local/state/$dir" ]]; then rm -f -- "$HOME/.local/state/$dir"; fi
  done
fi

# ---- Quickshell config (ours) ----
backup "$CFG/quickshell/ii"
mkdir -p "$CFG/quickshell"
rsync -a --delete --exclude '.git' "$DOTS/quickshell/ii/" "$CFG/quickshell/ii/"
# caelestia4: the shell doesn't hot-reload (Quickshell.watchFiles = false, see shell.qml): restart it, if it's running
# as a unit, once everything it reads (its files, config.json, shell.json, the units) is in place. On exit, so a step
# failing below doesn't leave the running shell on the old code with the new files on disk.
# Not when the plugin didn't build: a restart would load the new QML without it (the running shell still has the old one).
restart_shell() { ((PLUGIN_FAILED)) || systemctl --user try-restart caelestia4-shell.service 2>/dev/null || true; }
trap restart_shell EXIT
# caelestia4: Caelestia's app themes (btop / fastfetch / cava configs, Zen userChrome, the Caelestia extension in
# Cursor / VS Code / VSCodium); never replaces a file it didn't create. Colours then follow every scheme change.
python3 "$CFG/quickshell/ii/modules/caelestia/utils/scripts/apptheme.py" setup || warn "app themes setup failed"

# end-4 Python venv (end-4's installer makes it; ours didn't): terminal colours from the wallpaper
# (generate_colors_material.py), screen translator sign-in (google-auth), image regions / text colours (opencv).
# Python 3.12 as end-4 pins it (uv fetches it); locked deps from sdata/uv/requirements.txt.
# The stamp is written only after an install that worked: python alone doesn't mean its packages got there
VENV="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv"
VENV_STAMP="$VENV/.caelestia4-requirements"
VENV_WANT=$(sha256sum "$REPO/sdata/uv/requirements.txt" | cut -d' ' -f1)
if [[ -x "$VENV/bin/python" && "$(cat "$VENV_STAMP" 2>/dev/null)" == "$VENV_WANT" ]]; then
  say "kept existing $VENV"
elif command -v uv >/dev/null; then
  if { [[ -x "$VENV/bin/python" ]] || UV_NO_MODIFY_PATH=1 uv venv --prompt .venv "$VENV" -p 3.12; } \
    && VIRTUAL_ENV="$VENV" uv pip install -r "$REPO/sdata/uv/requirements.txt"; then
    printf '%s\n' "$VENV_WANT" > "$VENV_STAMP"
    say "$VENV is ready"
  else
    warn "end-4's Python venv isn't complete (no network, or a package failed to build): re-run this script to try again"
  fi
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
      --exclude 'hyprland/colors.lua' --exclude 'hyprlock/colors.conf' --exclude 'hyprlock/lockwall.conf' --exclude 'hyprlock/strings.conf' --exclude 'hyprlock/layout.conf' "$DOTS/hypr/" "$CFG/hypr/"
"$CFG/quickshell/ii/scripts/caelestia4/hyprlock-strings.sh" # hyprlock's text in the shell's language
"$CFG/quickshell/ii/scripts/caelestia4/hyprlock-layout.sh" || true # the layouts for these screens (hyprlock.conf sources the result)
[[ -f "$CFG/hypr/hyprlock/layout.conf" ]] || cp "$CFG/hypr/hyprlock/layout-full.conf" "$CFG/hypr/hyprlock/layout.conf"
[[ -f "$CFG/hypr/hyprland/colors.lua" ]] || cp "$DOTS/hypr/hyprland/colors.lua" "$CFG/hypr/hyprland/colors.lua"
# caelestia4: settings-app Hyprland options live here (written by the shell); never overwrite them
[[ -f "$CFG/hypr/hyprland/shellOverrides/main.lua" ]] || { mkdir -p "$CFG/hypr/hyprland/shellOverrides"; cp "$DOTS/hypr/hyprland/shellOverrides/main.lua" "$CFG/hypr/hyprland/shellOverrides/main.lua"; }
[[ -f "$CFG/hypr/hyprlock/colors.conf" ]] || cp "$DOTS/hypr/hyprlock/colors.conf" "$CFG/hypr/hyprlock/colors.conf"
# Variables a colours file from an older version lacks: the lock screen uses them all (the next scheme change rewrites it)
append_line() { # append_line <file> <text>: on a line of its own; a file that can't be written is only reported
  { [[ ! -s "$1" || -z "$(tail -c1 "$1")" ]] || printf '\n' >> "$1"; printf '%s\n' "$2" >> "$1"; } 2>/dev/null \
    || warn "couldn't update $1"
}
while IFS= read -r line; do
  var=${line%%=*}; var=${var%% *}
  grep -q "^[[:space:]]*${var}[[:space:]]*=" "$CFG/hypr/hyprlock/colors.conf" || append_line "$CFG/hypr/hyprlock/colors.conf" "$line"
done < <(grep '^\$' "$DOTS/hypr/hyprlock/colors.conf")
[[ -f "$CFG/hypr/hyprlock/lockwall.conf" ]] || cp "$DOTS/hypr/hyprlock/lockwall.conf" "$CFG/hypr/hyprlock/lockwall.conf"
[[ -d "$CFG/hypr/custom" ]] || cp -a "$DOTS/hypr/custom" "$CFG/hypr/custom"
# hypridle's timers: (re)create them from the saved settings when missing (5 / 10 / 15 min and lock before sleep by default)
if [[ ! -f "$CFG/hypr/hypridle-timeouts.conf" ]]; then
  read -r lockm offm sleepm lockb < <(jq -r '.caelestia.idle // {} | "\(.lockMinutes // 5) \(.screenOffMinutes // 10) \(.suspendMinutes // 15) \(.lockBeforeSleep // true)"' \
    "$CFG/illogical-impulse/config.json" 2>/dev/null || echo "5 10 15 true")
  "$CFG/quickshell/ii/scripts/caelestia4/hypridle-timeouts.sh" "${lockm:-5}" "${offm:-10}" "${sleepm:-15}" "${lockb:-true}" \
    && say "created $CFG/hypr/hypridle-timeouts.conf (idle: lock ${lockm}m, screen off ${offm}m, suspend ${sleepm}m)"
fi
# The keyboard from localectl when it isn't plain US (general.lua's default): the first login and the lock screen's
# password need the right one. Once only: what's in custom/general.lua or set in Nexus stays.
keyboard=$(localectl status 2>/dev/null || true)
kb_layout=$(sed -n 's/^ *X11 Layout: *//p' <<<"$keyboard")
kb_variant=$(sed -n 's/^ *X11 Variant: *//p' <<<"$keyboard")
kb_options=$(sed -n 's/^ *X11 Options: *//p' <<<"$keyboard")
if [[ "$kb_layout" =~ ^[a-zA-Z0-9_,-]+$ && "$kb_variant" =~ ^[a-zA-Z0-9_,-]*$ && "$kb_options" =~ ^[a-zA-Z0-9_,:-]*$ ]] \
  && [[ "$kb_layout" != us || -n "$kb_variant$kb_options" ]] \
  && ! grep -qs 'kb_layout' "$CFG/hypr/custom/general.lua"; then
  append_line "$CFG/hypr/custom/general.lua" "-- caelestia4: this machine's keyboard, from localectl at install
hl.config({ input = { kb_layout = \"$kb_layout\", kb_variant = \"$kb_variant\", kb_options = \"$kb_options\" } })"
  say "keyboard layout: $kb_layout${kb_variant:+ ($kb_variant)}"
fi
ENV="$CFG/hypr/custom/env.lua"
if ! grep -q 'QML_IMPORT_PATH' "$ENV" 2>/dev/null; then
  cat >> "$ENV" <<'LUA'

-- caelestia4: user-local Caelestia QML plugin, visible to Quickshell in this session only
hl.env("QML_IMPORT_PATH", os.getenv("HOME") .. "/.local/lib/qt6/qml")
LUA
fi
# caelestia4: an earlier version wrote card1 when the udev rule was missing, wrong on most machines (see below)
sed -i -e '/^-- caelestia4: render on the GPU that drives the monitor (RTX 5090)$/{N;/"\/dev\/dri\/card1"/d}' "$ENV" 2>/dev/null || true
# caelestia4: which GPU Hyprland is told to use is decided at each login, in uwsm/env-hyprland.d/caelestia4-local.sh. An
# earlier version also wrote it here, once, which stays after the monitor or the udev rule has gone. Only an env file that
# has the check can take over (it's kept once installed, so an old one may not)
if grep -qs 'AQ_DRM_DEVICES' "$CFG/uwsm/env-hyprland.d/caelestia4-local.sh"; then
  sed -i -e '/^-- caelestia4: render on the GPU that drives the monitor/{N;/hl\.env("AQ_DRM_DEVICES", "\/dev\/dri\/nvidia-dgpu")/d}' "$ENV" 2>/dev/null || true
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
import json, shutil, subprocess, sys
p = sys.argv[1]
d = json.load(open(p))
# caelestia4: Caelestia's monospace default isn't packaged here (CaskaydiaCove NF): JetBrains Mono NF comes with
# end-4's fonts. Without this, text like the keybind list falls back to a proportional font.
fonts = subprocess.run(["fc-list", ":", "family"], capture_output=True, text=True).stdout
level, font_changed = d, False
for key in ("appearance", "font", "mono"):
    level = level.get(key, {}) if isinstance(level, dict) else None
if isinstance(level, dict) and "family" not in level and "CaskaydiaCove" not in fonts:
    parent = d
    for key in ("appearance", "font", "mono"):
        parent = parent.setdefault(key, {})
        if not isinstance(parent, dict):  # a value of the user's in another form stays
            break
    else:
        parent["family"] = "JetBrains Mono NF"
        font_changed = True
# caelestia4: Atlas as the shell's file manager (Caelestia's default is Thunar), unless the user picked one
apps = d.setdefault("general", {}).setdefault("apps", {})
changed = apps.get("explorer", ["atlas"]) == ["atlas"] and not shutil.which("atlas")
if changed or "explorer" not in apps:  # not built (packaging/caelestia4-atlas): what there is
    apps["explorer"] = [next((a for a in ("atlas", "thunar", "dolphin", "nautilus") if shutil.which(a)), "xdg-open")]
    changed = True
cmds = d.setdefault("session", {}).setdefault("commands", {})
want = {"logout": ["uwsm", "stop"], "hibernate": ["systemctl", "hibernate"]}
if font_changed or changed or any(k not in cmds for k in want):
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
command -v caelestia >/dev/null || warn "caelestia-cli is not installed (step 4 of docs/install.md, packaging/caelestia4-cli): colours fall back to end-4's matugen"
mkdir -p "$HOME/.local/share/icons"; cp -n "$REPO/dots/.local/share/icons/illogical-impulse.svg" "$HOME/.local/share/icons/" 2>/dev/null || true

# ---- end-4 shell config: start in the caelestia family; never auto-kill KDE daemons ----
II="$CFG/illogical-impulse/config.json"
if [[ ! -f "$II" ]]; then
  mkdir -p "$(dirname "$II")"
  # lock.useHyprlock: hyprlock survives a screen dropping off DP on wake (the in-shell lock can lose its surface)
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

# caelestia4: Chromium and Electron pick their key store from the desktop's name, and an unknown one (Hyprland) gets the
# unencrypted "basic" store. Flags files get it too when they name no store (tools/keyring-switch.sh moved an old
# KWallet's keys, a separate matter)
# An account with a KWallet keeps its keys there until it's moved: the flag alone would lock its apps out of them
if [[ -e "${XDG_DATA_HOME:-$HOME/.local/share}/kwalletd/kdewallet.kwl" && ! -e "$CFG/brave-flags.conf" && ! -e "$CFG/chrome-flags.conf" ]]; then
  warn "this account has a KWallet: tools/keyring-switch.sh moves its keys and sets the browsers' key store"
else
  for f in chrome code thorium; do copy_file_if_missing "$DOTS/$f-flags.conf" "$CFG/$f-flags.conf"; done
  for f in chrome code thorium chromium brave brave-origin vesktop electron; do
    flags="$CFG/$f-flags.conf"
    grep -qsE '^[[:space:]]*--?password-store' "$flags" && continue
    # A file that's already there, on an account with a KWallet: only tools/keyring-switch.sh may change its store
    [[ -e "$flags" && -e "${XDG_DATA_HOME:-$HOME/.local/share}/kwalletd/kdewallet.kwl" ]] && continue
    backup "$flags"
    append_line "$flags" "# caelestia4: keys in gnome-keyring (libsecret)
--password-store=gnome-libsecret"
  done
fi

# ---- dirs caelestia-cli would normally create ----
mkdir -p "$STATE/caelestia" "${XDG_CACHE_HOME:-$HOME/.cache}/caelestia/imagecache/notifs"

[[ -d "$BK" ]] && say "backups: $BK" || say "nothing needed backing up"
# caelestia4: the session's env and user units come with the update too
if command -v uwsm >/dev/null && command -v uwsm-app >/dev/null; then
  "$REPO/tools/uwsm-setup.sh" || warn "tools/uwsm-setup.sh failed: the session's units may be old"
else
  warn "uwsm is not installed: sudo pacman -S --needed uwsm, then tools/uwsm-setup.sh"
fi
say "done. Log out and pick 'Hyprland (uwsm-managed)' on the login screen."

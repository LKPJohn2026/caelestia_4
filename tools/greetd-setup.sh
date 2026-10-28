#!/usr/bin/env bash
# caelestia4: set up greetd + ReGreet as the login screen (Plasma's login manager goes with Plasma:
# docs/dev/kde-removal.md, phase 2). Run as your user, not root: it reads your session's monitors, scheme, wallpaper
# and keyboard layout, builds the files, checks the greeter's Hyprland config, then asks for sudo to install them:
#   /etc/greetd/config.toml       greetd: Hyprland (as "greeter") with ReGreet in it
#   /etc/greetd/hyprland.lua      that Hyprland: your monitors and scale, no logo / news / animations
#   /etc/greetd/regreet.toml      ReGreet: adw-gtk3, Breeze icons, Bibata cursor, Google Sans Flex, Vietnamese clock
#   /etc/greetd/regreet.css       Caelestia's style (dots-extra/greetd/regreet.css.in) in the scheme's colours
#   /etc/greetd/background.*      a copy of the wallpaper (the greeter can't read your home folder)
#   /etc/pam.d/greetd             + pam_kwallet5 (and pam_gnome_keyring, inert until phase 3)
#   /usr/local/share/fonts/caelestia4/  Google Sans Flex for every user
# It doesn't switch the login manager; it prints the command for that. Re-run it to refresh colours / wallpaper.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/dots-extra/greetd"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
say() { printf '\e[1;34m::\e[0m %s\n' "$*"; }
[[ "$(id -u)" -ne 0 ]] || { echo "Run as your user, not root." >&2; exit 1; }
for c in greetd regreet Hyprland; do command -v "$c" >/dev/null || { echo "$c is not installed (pacman -S greetd greetd-regreet)" >&2; exit 1; }; done

OUT="${XDG_RUNTIME_DIR:-/tmp}/caelestia4-greetd"
mkdir -p "$OUT"

python3 - "$SRC" "$OUT" "$CFG" "$STATE" "${AQ_DRM_DEVICES:-}" <<'PY'
import json, os, re, shutil, subprocess, sys
src, out, cfg, state, aq = sys.argv[1:]

scheme = json.load(open(os.path.join(state, "caelestia/scheme.json")))
dark = scheme.get("mode", "dark") == "dark"
colours = scheme["colours"]

# Monitors: the hl.monitor blocks of the session's monitors.lua (Nexus > Display saves it)
mon = open(os.path.join(cfg, "hypr/monitors.lua")).read()
monitors = "\n".join(re.findall(r"hl\.monitor\(\{.*?\}\)", mon, re.S)) or 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })'

layout = json.loads(subprocess.run(["hyprctl", "getoption", "input:kb_layout", "-j"], capture_output=True, text=True).stdout or "{}").get("str") or "us"
locale = (os.environ.get("LC_TIME") or os.environ.get("LANG") or "en_US.UTF-8").split(".")[0]

# Wallpaper: end-4's path, or its first-frame thumbnail for a video
bg = json.load(open(os.path.join(cfg, "illogical-impulse/config.json"))).get("background", {})
wall = bg.get("wallpaperPath", "")
if re.search(r"\.(mp4|webm|mkv|avi|mov)$", wall, re.I):
    wall = bg.get("thumbnailPath", "")
ext = os.path.splitext(wall)[1].lower() or ".png"
bg_path = f"/etc/greetd/background{ext}"
if wall and os.path.exists(wall):
    shutil.copyfile(wall, os.path.join(out, f"background{ext}"))
else:
    bg_path = ""

def fill(name, values):
    text = open(os.path.join(src, name)).read()
    for k, v in values.items():
        text = text.replace(f"@{k}@", v)
    left = re.findall(r"@[A-Z_]+@", text)
    assert not left, f"{name}: unfilled {left}"
    return text

open(os.path.join(out, "hyprland.lua"), "w").write(fill("hyprland.lua.in", {
    "MONITORS": monitors, "BACKGROUND": colours["background"], "KB_LAYOUT": layout}))
open(os.path.join(out, "regreet.toml"), "w").write(fill("regreet.toml.in", {
    "BACKGROUND_PATH": bg_path, "DARK": "true" if dark else "false", "DARK_SUFFIX": "-dark" if dark else "",
    "ICON_THEME": "breeze-dark" if dark else "breeze", "LOCALE": locale}))
config = open(os.path.join(src, "config.toml")).read()
# The GPU the session uses (two-GPU machines: the monitors are on this one)
config = config.replace("env AQ_DRM_DEVICES=@AQ_DRM_DEVICES@ ", f"env AQ_DRM_DEVICES={aq} " if aq else "")
open(os.path.join(out, "config.toml"), "w").write(config)

# Colours: the GTK 4 colours caelestia-cli writes (cli.json enableGtk, for adw-gtk3's own widgets), without its
# imports of your other files, then Caelestia's style (regreet.css.in) with the scheme's colours filled in
css = os.path.join(cfg, "gtk-4.0/gtk.css")
lines = [l for l in open(css).read().splitlines() if not l.startswith("@import")] if os.path.exists(css) else []
style = open(os.path.join(src, "regreet.css.in")).read()
missing = sorted({m for m in re.findall(r"@([A-Za-z]+)@", style) if m not in colours})
assert not missing, f"regreet.css.in: colours the scheme doesn't have: {missing}"
style = re.sub(r"@([A-Za-z]+)@", lambda m: "#" + colours[m.group(1)], style)
open(os.path.join(out, "regreet.css"), "w").write(
    "/* caelestia4: Caelestia's colours for ReGreet (tools/greetd-setup.sh, from ~/.config/gtk-4.0/gtk.css) */\n"
    + "\n".join(lines) + "\n\n" + style)
print(f"monitors: {monitors.count('hl.monitor')}, layout: {layout}, clock: {locale}, mode: {'dark' if dark else 'light'}, "
      f"background: {os.path.basename(wall) if bg_path else 'none'}, GPU: {aq or 'default'}")
PY
cp "$SRC/pam-greetd" "$OUT/pam-greetd"

say "checking the greeter's Hyprland config"
Hyprland --verify-config -c "$OUT/hyprland.lua" 2>&1 | tail -3
say "files to install are in $OUT"

say "installing (sudo)"
sudo install -Dm644 "$OUT/config.toml" /etc/greetd/config.toml
sudo install -Dm644 "$OUT/hyprland.lua" /etc/greetd/hyprland.lua
sudo install -Dm644 "$OUT/regreet.toml" /etc/greetd/regreet.toml
sudo install -Dm644 "$OUT/regreet.css" /etc/greetd/regreet.css
for f in "$OUT"/background.*; do [[ -e "$f" ]] && sudo install -Dm644 "$f" "/etc/greetd/$(basename "$f")"; done
[[ -e /etc/pam.d/greetd.caelestia4-orig ]] || sudo cp /etc/pam.d/greetd /etc/pam.d/greetd.caelestia4-orig
sudo install -Dm644 "$OUT/pam-greetd" /etc/pam.d/greetd
sudo install -Dm644 -t /usr/local/share/fonts/caelestia4 \
    "$REPO/dots/.config/quickshell/ii/modules/caelestia/assets/google-sans-flex/"*.ttf
sudo fc-cache -f /usr/local/share/fonts >/dev/null
say "installed /etc/greetd, /etc/pam.d/greetd (greetd's own kept as greetd.caelestia4-orig), the font"

cat <<'EOF'

If greetd isn't the login screen yet (then reboot):
  sudo systemctl enable greetd.service
If the login screen doesn't come up: Ctrl+Alt+F2, log in, journalctl -b -u greetd and /var/log/regreet/log
EOF

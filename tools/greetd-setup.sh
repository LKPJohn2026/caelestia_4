#!/usr/bin/env bash
# caelestia4: set up greetd + ReGreet as the login screen (Plasma's login manager goes with Plasma:
# docs/dev/kde-removal.md, phase 2). Run as your user, not root: it reads your session's monitors, scheme, wallpaper
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

python3 - "$SRC" "$OUT" "$CFG" "$STATE" "${AQ_DRM_DEVICES:-}" <<'PY'
import json, os, re, shutil, subprocess, sys
src, out, cfg, state, aq = sys.argv[1:]

# The scheme, or a neutral dark one before any was generated (re-run after that for your colours)
needed = set(re.findall(r"@([A-Za-z]+)@", open(os.path.join(src, "regreet.css.in")).read())) | {"background"}
try:
    scheme = json.load(open(os.path.join(state, "caelestia/scheme.json")))
    if not needed <= set(scheme["colours"]):
        raise ValueError
except (OSError, ValueError, KeyError, TypeError):
    scheme = json.load(open(os.path.join(src, "default-scheme.json")))
    print("no complete colour scheme yet: using a neutral dark one")
dark = scheme.get("mode", "dark") == "dark"
colours = scheme["colours"]

# Monitors: the hl.monitor blocks of the session's monitors.lua (Nexus > Display saves it)
try:
    mon = open(os.path.join(cfg, "hypr/monitors.lua")).read()
except OSError:  # none saved yet: Hyprland's defaults
    mon = ""
monitors = "\n".join(re.findall(r"hl\.monitor\(\{.*?\}\)", mon, re.S)) or 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })'

# The session's keyboard; outside a session (a TTY, SSH), the machine's
try:
    layout = json.loads(subprocess.run(["hyprctl", "getoption", "input:kb_layout", "-j"], capture_output=True, text=True).stdout).get("str")
except (OSError, ValueError, AttributeError):
    layout = ""
if not layout:
    try:
        found = re.search(r"X11 Layout: *(\S+)", subprocess.run(["localectl", "status"], capture_output=True, text=True).stdout)
    except OSError:
        found = None
    layout = found.group(1) if found else "us"
locale = (os.environ.get("LC_TIME") or os.environ.get("LANG") or "en_US.UTF-8").split(".")[0]

# Wallpaper: end-4's path, or its first-frame thumbnail for a video
try:
    shell_config = json.load(open(os.path.join(cfg, "illogical-impulse/config.json")))
    shell_config = shell_config if isinstance(shell_config, dict) else {}
except (OSError, ValueError):
    shell_config = {}
bg = shell_config.get("background") or {}
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
# In the shell's language (its catalogue), else the locale's
ui = (shell_config.get("language") or {}).get("ui", "auto")
if ui == "auto":
    ui = (os.environ.get("LC_MESSAGES") or os.environ.get("LANG") or "").split(".")[0]
try:
    catalogue = json.load(open(os.path.join(src, "../../dots/.config/quickshell/ii/translations", f"{ui}.json")))
except (OSError, ValueError):
    catalogue = {}
def tr(text):
    return (catalogue.get(text) or text).removesuffix("/*keep*/").strip()
open(os.path.join(out, "regreet.toml"), "w").write(fill("regreet.toml.in", {
    "GREETING": tr("Welcome back!"),
    # with words of its own only in the clock's locale: weekday and month names come from that
    "DATE_FORMAT": tr("%A, %d %B") if ui.split("_")[0] == locale.split("_")[0] else "%A, %d %B",
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

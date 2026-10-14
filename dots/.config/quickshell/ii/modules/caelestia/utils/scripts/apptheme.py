#!/usr/bin/env python3
"""caelestia4: Caelestia's app themes (caelestia-dots/cli utils/theme.py, ff8cae3) on top of end-4's colour pipeline.

`apply` runs after every colour change (end of scripts/colors/applycolor.sh, which both wallpaper colours and preset
schemes reach) and reads that change's palette from material_colors.scss:
  - ~/.local/state/caelestia/scheme.json  the file Caelestia's own integrations watch (the VS Code / Cursor extension)
  - btop    ~/.config/btop/themes/caelestia.theme (btop reloads on SIGUSR2)
  - cava    ~/.config/cava/config, only while it is ours (first line marker), cava reloads on SIGUSR2
  - Zed     ~/.config/zed/themes/caelestia.json (Zed watches it)
  - Zen     <profile>/chrome/caelestia.css, imported by a userChrome.css we created (read when Zen starts)
  - Brave   /etc/brave/policies/managed/caelestia.json BrowserThemeColor, if that directory is writable for us
  - Thunar  ~/.config/gtk-3.0/thunar.css (only .thunar selectors), imported from gtk.css (the import is re-added
            if Plasma rewrites gtk.css); read when Thunar starts
  - Spotify ~/.config/spicetify/Themes/caelestia/color.ini; `spicetify watch -s` (the music special workspace starts
            Spotify that way) applies it live
  - nvim    nothing to write: its caelestia colorscheme watches scheme.json itself
  - micro   nothing to write: the "simple" colorscheme uses the terminal colours end-4 already sets
`setup` adds the one-time parts, never replacing a file that isn't ours: btop.conf, fastfetch config, cava config,
Zen userChrome.css + user.js pref, the Caelestia extension in Cursor / VS Code, Thunar's custom actions, the
spicetify theme, the nvim colorscheme (+ an init.lua if there is none), micro's "simple" colorscheme. Then `apply`.

Wallpaper colours have no Catppuccin-style accents (red, blue, lavender...) that Caelestia's templates use; they are
derived from the wallpaper-harmonised terminal colours and surface roles, as Caelestia's presets map them.
"""
import json, os, re, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.abspath(os.path.join(HERE, "../../assets/apps"))
HOME = os.path.expanduser("~")
CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config")
STATE = os.environ.get("XDG_STATE_HOME") or os.path.join(HOME, ".local/state")
SCSS = os.path.join(STATE, "quickshell/user/generated/material_colors.scss")
SCHEME_STATE = os.path.join(STATE, "caelestia4/scheme.json")  # preset choice (scheme.py)
MARKER = "caelestia4: generated"

# Catppuccin-style names -> where they come from when the scheme doesn't have them (wallpaper colours)
DERIVED = {
    "rosewater": "term15", "flamingo": "term13", "pink": "term13", "mauve": "term5", "red": "term1",
    "maroon": "term9", "peach": "term11", "yellow": "term3", "green": "term2", "teal": "term6",
    "sky": "term14", "sapphire": "term12", "blue": "term4", "lavender": "term12",
    "text": "onSurface", "subtext1": "onSurfaceVariant", "subtext0": "outline",
    "overlay2": "outline", "overlay1": "outline", "overlay0": "outlineVariant",
    "surface2": "outlineVariant", "surface1": "surfaceContainerHighest", "surface0": "surfaceContainerHigh",
    "base": "surface", "mantle": "surfaceContainerLow", "crust": "surfaceContainerLowest",
}


def read_palette():
    colours, dark = {}, True
    with open(SCSS) as f:
        for line in f:
            m = re.match(r"\$(\w+):\s*(.+?);", line.strip())
            if not m:
                continue
            key, value = m.groups()
            if key == "darkmode":
                dark = value.strip().lower() == "true"
            elif re.fullmatch(r"#[0-9A-Fa-f]{6}", value.strip()):
                colours[key] = value.strip()[1:].lower()
    for name, src in DERIVED.items():
        if name not in colours and src in colours:
            colours[name] = colours[src]
    return colours, "dark" if dark else "light"


def atomic_write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.islink(path):  # editors / Zed don't see changes made through a symlink
        os.unlink(path)
    tmp = f"{path}.tmp{os.getpid()}"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, path)


def fill(template, colours, mode, hash_=True):
    text = open(os.path.join(ASSETS, "templates", template)).read()
    # {{ $role }} (Caelestia's static templates)
    text = re.sub(r"\{\{\s*\$(\w+)\s*\}\}",
                  lambda m: (("#" if hash_ else "") + colours[m.group(1)]) if m.group(1) in colours else m.group(0), text)
    # {{ role.hex }} and {{ mode }} (dynamic templates: zed.json)
    text = re.sub(r"\{\{\s*(\w+)\.hex\s*\}\}", lambda m: colours.get(m.group(1), m.group(0)), text)
    return re.sub(r"\{\{\s*mode\s*\}\}", mode, text)


def signal(proc, sig="USR2"):
    subprocess.run(["pkill", f"-{sig}", "-x", proc], stderr=subprocess.DEVNULL)


def ours(path):
    try:
        with open(path) as f:
            return MARKER in f.read(400)
    except FileNotFoundError:
        return False


def zen_profiles():
    """Profile dirs of Zen installs (Zen keeps them in ~/.config/zen, older builds in ~/.zen)"""
    out = []
    for root in (os.path.join(CONFIG, "zen"), os.path.join(HOME, ".zen")):
        ini = os.path.join(root, "installs.ini")
        if not os.path.exists(ini):
            continue
        for line in open(ini):
            if line.startswith("Default="):
                p = os.path.join(root, line.split("=", 1)[1].strip())
                if os.path.isdir(p) and p not in out:
                    out.append(p)
    return out


# ---------------------------------------------------------------- apply (every colour change)

def apply():
    colours, mode = read_palette()
    try:
        preset = json.load(open(SCHEME_STATE))
    except Exception:
        preset = {}
    name = preset.get("name") or "dynamic"
    atomic_write(os.path.join(STATE, "caelestia/scheme.json"), json.dumps({
        "name": name,
        "flavour": preset.get("flavour") or "default",
        "mode": mode,
        "variant": "tonalspot",
        "colours": colours,
    }))

    atomic_write(os.path.join(CONFIG, "btop/themes/caelestia.theme"), fill("btop.theme", colours, mode))
    signal("btop")

    cava = os.path.join(CONFIG, "cava/config")
    if ours(cava):
        atomic_write(cava, f"# {MARKER} by apptheme.py, edits are overwritten\n" + fill("cava.conf", colours, mode))
        signal("cava")

    if shutil.which("zeditor") or shutil.which("zed") or os.path.isdir(os.path.join(CONFIG, "zed")):
        atomic_write(os.path.join(CONFIG, "zed/themes/caelestia.json"), fill("zed.json", colours, mode, hash_=False))

    for profile in zen_profiles():
        if ours(os.path.join(profile, "chrome/userChrome.css")):
            atomic_write(os.path.join(profile, "chrome/caelestia.css"), fill("zen.css", colours, mode))

    if shutil.which("thunar"):
        gtk = os.path.join(CONFIG, "gtk-3.0")
        atomic_write(os.path.join(gtk, "thunar.css"), fill("thunar.css", colours, mode))
        ensure_gtk_import(gtk)

    if shutil.which("spicetify"):
        atomic_write(os.path.join(CONFIG, "spicetify/Themes/caelestia/color.ini"),
                     fill(f"spicetify-{mode}.ini", colours, mode, hash_=False))

    policy_dir = "/etc/brave/policies/managed"
    if shutil.which("brave") and os.access(policy_dir, os.W_OK):
        atomic_write(os.path.join(policy_dir, "caelestia.json"),
                     json.dumps({"BrowserThemeColor": f"#{colours['surface']}", "BrowserColorScheme": "device"}))
        # Only a running Brave: with no window open this would start one in the background
        if subprocess.run(["pidof", "brave"], stdout=subprocess.DEVNULL).returncode == 0:
            subprocess.Popen(["brave", "--refresh-platform-policy", "--no-startup-window"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def ensure_gtk_import(gtk):
    """gtk.css imports thunar.css (GTK 3 only reads gtk.css); added back when Plasma's colour sync rewrites the file"""
    path = os.path.join(gtk, "gtk.css")
    line = '@import "thunar.css"; /* caelestia4: Thunar colours, apptheme.py */'
    text = open(path).read() if os.path.exists(path) else ""
    if "thunar.css" not in text:
        atomic_write(path, text + ("" if text.endswith("\n") or not text else "\n") + line + "\n")


# ---------------------------------------------------------------- setup (once; never replaces a file that isn't ours)

def install_if_missing(src, dest):
    if os.path.exists(dest):
        print(f"kept {dest}")
        return
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copyfile(os.path.join(ASSETS, src), dest)
    print(f"installed {dest}")


def setup():
    install_if_missing("btop/btop.conf", os.path.join(CONFIG, "btop/btop.conf"))
    install_if_missing("fastfetch/config.jsonc", os.path.join(CONFIG, "fastfetch/config.jsonc"))

    cava = os.path.join(CONFIG, "cava/config")
    if not os.path.exists(cava):
        atomic_write(cava, f"# {MARKER} by apptheme.py, edits are overwritten\n")
        print(f"installed {cava}")

    for profile in zen_profiles():
        chrome = os.path.join(profile, "chrome/userChrome.css")
        if not os.path.exists(chrome):
            atomic_write(chrome, f"/* {MARKER} by apptheme.py: Caelestia colours for Zen */\n@import url(\"caelestia.css\");\n")
            print(f"installed {chrome}")
        userjs = os.path.join(profile, "user.js")
        pref = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
        if pref not in (open(userjs).read() if os.path.exists(userjs) else ""):
            with open(userjs, "a") as f:
                f.write(f"// {MARKER}: let Zen load chrome/userChrome.css\n{pref}\n")
            print(f"added the userChrome pref to {userjs}")

    # Thunar: custom actions (open a terminal here...) and removable-media settings, as Caelestia
    install_if_missing("thunar/uca.xml", os.path.join(CONFIG, "Thunar/uca.xml"))
    install_if_missing("thunar/thunar-volman.xml", os.path.join(CONFIG, "xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml"))

    # nvim: Caelestia's colorscheme (follows scheme.json live); a minimal init.lua only when there is no config
    install_if_missing("nvim/caelestia.lua", os.path.join(CONFIG, "nvim/colors/caelestia.lua"))
    nvim = os.path.join(CONFIG, "nvim")
    if not any(os.path.exists(os.path.join(nvim, f)) for f in ("init.lua", "init.vim")):
        atomic_write(os.path.join(nvim, "init.lua"),
                     f"-- {MARKER} by apptheme.py: Caelestia's colorscheme, which follows the desktop colours\n"
                     "vim.opt.termguicolors = true\npcall(vim.cmd.colorscheme, \"caelestia\")\n")
        print(f"installed {nvim}/init.lua")

    # micro: Caelestia uses "simple", which draws with the terminal palette (so it follows the desktop colours)
    micro = os.path.join(CONFIG, "micro/settings.json")
    if shutil.which("micro"):
        try:
            conf = json.load(open(micro)) if os.path.exists(micro) else {}
        except Exception:
            conf = None  # not valid JSON: leave it alone
        if conf is not None and conf.get("colorscheme") != "simple":
            print(f"micro colorscheme: {conf.get('colorscheme', 'default')} -> simple")
            conf["colorscheme"] = "simple"
            atomic_write(micro, json.dumps(conf, indent=4) + "\n")

    # Spotify: the caelestia spicetify theme (colours from apply)
    if shutil.which("spicetify"):
        install_if_missing("spicetify/user.css", os.path.join(CONFIG, "spicetify/Themes/caelestia/user.css"))
        r = subprocess.run(["spicetify", "config", "current_theme", "caelestia", "color_scheme", "caelestia"],
                           capture_output=True, text=True)
        print("spicetify theme:", "set" if r.returncode == 0 else (r.stderr or r.stdout).strip()[-200:])

    vsix = next((os.path.join(ASSETS, "vscode", f) for f in os.listdir(os.path.join(ASSETS, "vscode")) if f.endswith(".vsix")), None)
    for editor in ("cursor", "code", "codium"):
        if vsix and shutil.which(editor):
            r = subprocess.run([editor, "--install-extension", vsix, "--force"], capture_output=True, text=True)
            print(f"{editor}: {'installed' if r.returncode == 0 else 'failed: ' + (r.stderr or r.stdout).strip()[-200:]} {os.path.basename(vsix)}")

    apply()


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "apply"
    {"apply": apply, "setup": setup}.get(cmd, lambda: sys.exit(__doc__))()

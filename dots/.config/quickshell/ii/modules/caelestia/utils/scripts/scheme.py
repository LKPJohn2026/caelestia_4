#!/usr/bin/env python3
"""caelestia4: the desktop's colour scheme, made by caelestia-cli (backend step 3).

caelestia-cli owns the scheme: wallpaper colours ("dynamic", with a Material variant) or one of its preset schemes
(catppuccin, gruvbox, nord, ...). It keeps the result in ~/.local/state/caelestia/scheme.json, which Caelestia's
shell parts read directly, and themes btop / nvtop / Zed / Spotify itself (~/.config/caelestia/cli.json). After every
change it runs its postHook, `scheme.py bridge`, which hands the same colours to end-4's outputs:
  - `matugen json` renders end-4's templates (shell colours.json, Hyprland, hyprlock, fuzzel) from the scheme
  - material_colors.scss + applycolor.sh: terminal colours (the scheme's term0-15), kitty, the remaining app themes
end-4's switchwall.sh stays the entry point for wallpapers, light/dark and the colour style; it calls `wall` and `mode`.

Usage:
  scheme.py list                      JSON {name: {flavour: {mode: {role: "rrggbb"}}}} (preview roles only)
  scheme.py get                       JSON {"name", "flavour", "mode", "variant"} (name "dynamic" = wallpaper colours)
  scheme.py set dynamic [--mode M]    wallpaper colours
  scheme.py set NAME FLAVOUR [--mode M]
  scheme.py wall IMAGE                tell caelestia-cli the wallpaper (an image; a video's first frame)
  scheme.py mode [M] [--variant V] [--dynamic]
                                      light/dark (a preset without that mode switches flavour, see counterpart()),
                                      the Material variant, and --dynamic to leave a preset for wallpaper colours
  scheme.py bridge                    caelestia-cli's postHook: pass the current scheme to end-4
"""
import importlib.util, json, os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
II = os.path.abspath(os.path.join(HERE, "../../../.."))  # ~/.config/quickshell/ii
SCRIPTS = os.path.join(II, "scripts/colors")
HOME = os.path.expanduser("~")
STATE = os.environ.get("XDG_STATE_HOME") or os.path.join(HOME, ".local/state")
CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config")
SCHEME_JSON = os.path.join(STATE, "caelestia/scheme.json")  # caelestia-cli's
WALL_PATH = os.path.join(STATE, "caelestia/wallpaper/path.txt")  # caelestia-cli's
GENERATED = os.path.join(STATE, "quickshell/user/generated")
SHELL_CONFIG = os.path.join(CONFIG, "illogical-impulse/config.json")
SHARED_DESKTOP = os.path.join(CONFIG, "caelestia4/shared-desktop")

PREVIEW = ["primary", "secondary", "tertiary", "surface", "surfaceContainer", "onSurface", "outline", "primaryContainer"]
# matugen roles that have no camelCase twin in caelestia's colours
EXTRA = {"source_color": "primary_paletteKeyColor"}
# end-4's colour styles (appearance.palette.type, matugen --type) -> caelestia-cli variants
VARIANTS = {
    "scheme-tonal-spot": "tonalspot", "scheme-vibrant": "vibrant", "scheme-expressive": "expressive",
    "scheme-fidelity": "fidelity", "scheme-fruit-salad": "fruitsalad", "scheme-monochrome": "monochrome",
    "scheme-neutral": "neutral", "scheme-rainbow": "rainbow", "scheme-content": "content",
}


def schemes_dir():
    """caelestia-cli's preset schemes (data/schemes in its package); our copy if it isn't installed"""
    spec = importlib.util.find_spec("caelestia")
    if spec and spec.origin:
        d = os.path.join(os.path.dirname(spec.origin), "data/schemes")
        if os.path.isdir(d):
            return d
    return os.path.join(II, "modules/caelestia/assets/schemes")


SCHEMES = schemes_dir()


def read_scheme(name, flavour, mode):
    colours = {}
    with open(os.path.join(SCHEMES, name, flavour, f"{mode}.txt")) as f:
        for line in f:
            parts = line.split()
            if len(parts) == 2:
                colours[parts[0]] = parts[1].lower()
    return colours


def modes_of(name, flavour):
    d = os.path.join(SCHEMES, name, flavour)
    return sorted(f[:-4] for f in os.listdir(d) if f.endswith(".txt"))


def pick_mode(name, flavour, mode):
    """The requested mode if the preset has it, else the one it has (most presets are dark-only)"""
    modes = modes_of(name, flavour)
    if not modes:
        raise SystemExit(f"scheme {name}/{flavour} has no colour files")
    return mode if mode in modes else modes[0]


def counterpart(name, flavour, mode):
    """When the light/dark switch asks for a mode this flavour doesn't have, the flavour of the same scheme to
    switch to (e.g. catppuccin mocha -> latte for light), or None to keep the current flavour in its own mode.
    Flavours per scheme and their modes: see SCHEMES/<name>/<flavour>/{dark,light}.txt (modes_of())."""
    # TODO(human)
    return None


def load_scheme():
    try:
        with open(SCHEME_JSON) as f:
            return json.load(f)
    except Exception:
        return {"name": "dynamic", "flavour": "default", "mode": "dark", "variant": "tonalspot", "colours": {}}


def caelestia(*args):
    return subprocess.run(["caelestia", *args], check=False).returncode == 0


def wallpaper_path():
    try:
        with open(SHELL_CONFIG) as f:
            bg = json.load(f)["background"]
        path = bg["wallpaperPath"]
        if re.search(r"\.(mp4|webm|mkv|avi|mov)$", path, re.I) and bg.get("thumbnailPath"):
            return bg["thumbnailPath"]
        return path
    except Exception:
        return ""


def ensure_wallpaper():
    """caelestia-cli needs a wallpaper before it can make a dynamic scheme"""
    if not os.path.exists(WALL_PATH) and (wall := wallpaper_path()):
        caelestia("wallpaper", "-f", wall, "--no-smart")


def apply_to_end4(colours, mode):
    # 1. end-4's templates via matugen, fed the scheme instead of generating from an image.
    #    Every role gets the same value for dark / light / default (the scheme is already one mode).
    roles = {snake(k): v for k, v in colours.items() if not k.startswith("term")}
    for role, src in EXTRA.items():
        if src in colours:
            roles[role] = colours[src]
    data = {
        "colors": {r: {m: {"color": f"#{v}"} for m in ("dark", "default", "light")} for r, v in roles.items()},
        "image": wallpaper_path(),
        "is_dark_mode": mode == "dark",
        "mode": mode.capitalize(),
    }
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
        json.dump(data, f)
        tmp = f.name
    try:
        subprocess.run(["matugen", "json", tmp, "--mode", mode, "--quiet"], check=True)
    finally:
        os.unlink(tmp)

    # 2. Terminal colours and the remaining app themes: end-4's applycolor.sh reads "$name: #HEX;" lines
    os.makedirs(GENERATED, exist_ok=True)
    lines = [f"$darkmode: {mode == 'dark'};", "$transparent: False;"]
    lines += [f"${k}: #{v.upper()};" for k, v in colours.items()]
    with open(os.path.join(GENERATED, "material_colors.scss"), "w") as f:
        f.write("\n".join(lines) + "\n")
    subprocess.run([os.path.join(SCRIPTS, "applycolor.sh")], check=False)

    # 3. GTK light/dark preference, as switchwall.sh does (skipped on an account shared with Plasma)
    if not os.path.exists(SHARED_DESKTOP):
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme",
                        "prefer-dark" if mode == "dark" else "prefer-light"], check=False)


def snake(camel):
    return re.sub(r"(?<=[a-z0-9])([A-Z])", r"_\1", camel).lower()


def take(args, flag, valued=True):
    if flag not in args:
        return None
    i = args.index(flag)
    if not valued:
        del args[i]
        return True
    value = args[i + 1]
    del args[i:i + 2]
    return value


def main():
    args = sys.argv[1:]
    mode = take(args, "--mode")
    if mode not in (None, "dark", "light"):
        raise SystemExit("--mode must be dark or light")
    cmd = args[0] if args else "get"
    scheme = load_scheme()

    if cmd == "list":
        out = {}
        for name in sorted(os.listdir(SCHEMES)):
            if not os.path.isdir(os.path.join(SCHEMES, name)):
                continue
            for flavour in sorted(os.listdir(os.path.join(SCHEMES, name))):
                for m in modes_of(name, flavour):
                    c = read_scheme(name, flavour, m)
                    out.setdefault(name, {}).setdefault(flavour, {})[m] = {k: c[k] for k in PREVIEW if k in c}
        print(json.dumps(out))
    elif cmd == "get":
        print(json.dumps({k: scheme.get(k, "") for k in ("name", "flavour", "mode", "variant")}))
    elif cmd == "set" and len(args) >= 2 and args[1] == "dynamic":
        ensure_wallpaper()
        caelestia("scheme", "set", "--notify", "-n", "dynamic", "-m", mode or scheme.get("mode", "dark"))
    elif cmd == "set" and len(args) >= 3:
        name, flavour = args[1], args[2]
        if not os.path.isdir(os.path.join(SCHEMES, name, flavour)):
            raise SystemExit(f"unknown scheme {name} {flavour}")
        mode = pick_mode(name, flavour, mode or scheme.get("mode", "dark"))
        caelestia("scheme", "set", "--notify", "-n", name, "-f", flavour, "-m", mode)
    elif cmd == "wall" and len(args) >= 2:
        try:
            with open(WALL_PATH) as f:
                same = f.read().strip() == os.path.realpath(args[1])
        except OSError:
            same = False
        if not same:  # the same path again would only re-run every theme
            caelestia("wallpaper", "-f", args[1], "--no-smart")
    elif cmd == "mode":
        variant = VARIANTS.get(take(args, "--variant") or "", None)
        dynamic = take(args, "--dynamic", valued=False) or scheme.get("name") == "dynamic"
        wanted = args[1] if len(args) >= 2 else mode
        opts = []
        if dynamic:
            ensure_wallpaper()
            if scheme.get("name") != "dynamic":
                opts += ["-n", "dynamic"]
            if variant and variant != scheme.get("variant"):
                opts += ["-v", variant]
            if wanted and wanted != scheme.get("mode"):
                opts += ["-m", wanted]
        elif wanted and wanted != scheme.get("mode"):
            name, flavour = scheme["name"], scheme["flavour"]
            if wanted not in modes_of(name, flavour):
                flavour = counterpart(name, flavour, wanted) or flavour
                if flavour != scheme["flavour"]:
                    opts += ["-f", flavour]
            m = pick_mode(name, flavour, wanted)
            if m != scheme.get("mode"):
                opts += ["-m", m]
        if opts:
            caelestia("scheme", "set", "--notify", *opts)
    elif cmd == "bridge":
        colours = json.loads(os.environ["SCHEME_COLOURS"]) if os.environ.get("SCHEME_COLOURS") else scheme["colours"]
        apply_to_end4(colours, os.environ.get("SCHEME_MODE") or scheme.get("mode", "dark"))
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()

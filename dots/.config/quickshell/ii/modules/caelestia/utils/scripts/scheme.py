#!/usr/bin/env python3
"""caelestia4: colour scheme source for the whole desktop: the wallpaper (end-4's matugen pipeline, "dynamic") or one
of Caelestia's preset schemes (catppuccin, gruvbox, nord, ...; files in ../../assets/schemes).

A preset is applied through the same outputs as a wallpaper scheme, so everything end-4 themes follows it:
  - `matugen json` renders end-4's templates (shell colours.json, Hyprland, hyprlock, fuzzel) from the preset
  - material_colors.scss + applycolor.sh: terminal colours (the preset's own term0-15)
The choice is kept in $XDG_STATE_HOME/caelestia4/scheme.json. While a preset is active, switchwall.sh keeps it when
the wallpaper or the light/dark mode changes (it calls `scheme.py apply`); picking "dynamic" returns to wallpaper
colours.

Usage:
  scheme.py list                      JSON {name: {flavour: {mode: {role: "rrggbb"}}}} (preview roles only)
  scheme.py get                       JSON {"name", "flavour", "mode"} (name "dynamic" = wallpaper colours)
  scheme.py set dynamic [--mode M]    wallpaper colours (re-runs switchwall.sh on the current wallpaper)
  scheme.py set NAME FLAVOUR [--mode M]
  scheme.py apply [--mode M]          re-apply the active preset (exit 1 if none is active)
  scheme.py clear                     forget the preset without applying anything (switchwall.sh --color / --type)
"""
import json, os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
II = os.path.abspath(os.path.join(HERE, "../../../.."))  # ~/.config/quickshell/ii
SCHEMES = os.path.join(II, "modules/caelestia/assets/schemes")
SCRIPTS = os.path.join(II, "scripts/colors")
HOME = os.path.expanduser("~")
STATE = os.environ.get("XDG_STATE_HOME") or os.path.join(HOME, ".local/state")
CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config")
STATE_FILE = os.path.join(STATE, "caelestia4/scheme.json")
GENERATED = os.path.join(STATE, "quickshell/user/generated")
SHELL_CONFIG = os.path.join(CONFIG, "illogical-impulse/config.json")
SHARED_DESKTOP = os.path.join(CONFIG, "caelestia4/shared-desktop")

PREVIEW = ["primary", "secondary", "tertiary", "surface", "surfaceContainer", "onSurface", "outline", "primaryContainer"]
# matugen roles that have no camelCase twin in the preset files
EXTRA = {"source_color": "primary_paletteKeyColor"}


def read_scheme(name, flavour, mode):
    path = os.path.join(SCHEMES, name, flavour, f"{mode}.txt")
    colours = {}
    with open(path) as f:
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


def current_mode():
    """dark/light from the colours on screen now (end-4's colours.json)"""
    try:
        with open(os.path.join(GENERATED, "colors.json")) as f:
            bg = json.load(f)["background"].lstrip("#")
        r, g, b = (int(bg[i:i + 2], 16) for i in (0, 2, 4))
        return "dark" if (0.299 * r + 0.587 * g + 0.114 * b) < 128 else "light"
    except Exception:
        return "dark"


def load_state():
    try:
        with open(STATE_FILE) as f:
            s = json.load(f)
        if s.get("name") and s.get("name") != "dynamic":
            return s
    except Exception:
        pass
    return {"name": "dynamic", "flavour": "", "mode": current_mode()}


def save_state(state):
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    tmp = STATE_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f)
    os.replace(tmp, STATE_FILE)


def snake(camel):
    return re.sub(r"(?<=[a-z0-9])([A-Z])", r"_\1", camel).lower()


def wallpaper_path():
    try:
        with open(SHELL_CONFIG) as f:
            return json.load(f)["background"]["wallpaperPath"]
    except Exception:
        return ""


def apply_preset(name, flavour, mode):
    colours = read_scheme(name, flavour, mode)

    # 1. end-4's templates via matugen, fed the preset instead of generating from an image.
    #    Every role gets the same value for dark / light / default (the preset is already one mode).
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

    # 2. Terminal colours: end-4's applycolor.sh reads "$name: #HEX;" lines (term0-15 + Material roles)
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


def arg_mode(args):
    if "--mode" in args:
        i = args.index("--mode")
        mode = args[i + 1]
        del args[i:i + 2]
        if mode not in ("dark", "light"):
            raise SystemExit("--mode must be dark or light")
        return mode
    return None


def main():
    args = sys.argv[1:]
    mode = arg_mode(args)
    cmd = args[0] if args else "get"

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
        print(json.dumps(load_state()))
    elif cmd == "clear":
        save_state({"name": "dynamic", "flavour": "", "mode": current_mode()})
    elif cmd == "set" and len(args) >= 2 and args[1] == "dynamic":
        mode = mode or current_mode()
        save_state({"name": "dynamic", "flavour": "", "mode": mode})
        subprocess.run([os.path.join(SCRIPTS, "switchwall.sh"), "--noswitch", "--mode", mode], check=False)
    elif cmd == "set" and len(args) >= 3:
        name, flavour = args[1], args[2]
        if not os.path.isdir(os.path.join(SCHEMES, name, flavour)):
            raise SystemExit(f"unknown scheme {name} {flavour}")
        mode = pick_mode(name, flavour, mode or current_mode())
        save_state({"name": name, "flavour": flavour, "mode": mode})
        apply_preset(name, flavour, mode)
    elif cmd == "apply":
        state = load_state()
        if state["name"] == "dynamic":
            sys.exit(1)
        mode = pick_mode(state["name"], state["flavour"], mode or state.get("mode") or "dark")
        save_state({**state, "mode": mode})
        apply_preset(state["name"], state["flavour"], mode)
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()

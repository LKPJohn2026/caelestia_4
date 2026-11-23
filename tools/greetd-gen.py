#!/usr/bin/env python3
"""caelestia4: build the login screen's files for tools/greetd-setup.sh, which checks and installs them as root.

  python3 -I tools/greetd-gen.py SRC OUT CONFIG_HOME STATE_HOME AQ_DRM_DEVICES

SRC is dots-extra/greetd; OUT gets config.toml, hyprland.lua, regreet.toml, regreet.css and background.<ext>.
Nothing here is pasted into regreet.toml as it is: every value is a TOML string with its quotes and control
characters escaped, the wallpaper's extension, the locale and the language are allow-listed, and the result must
parse with the template's tables and nothing more (ReGreet passes an [env] table to every session it starts).
config.toml gets the GPU only as /dev/dri paths and must be the template with that filled in (no [initial_session]);
hyprland.lua gets the keyboard layout only as layout names, the colours (there and in regreet.css) only as hex, and
the monitors only as allow-listed fields of each hl.monitor rule, written again (never the user's Lua as it is).
"""
import importlib.util, json, os, re, shutil, subprocess, sys, tomllib

src, out, cfg, state, aq = sys.argv[1:]

# The scheme, or a neutral dark one before any was generated (re-run after that for your colours)
needed = set(re.findall(r"@([A-Za-z]+)@", open(os.path.join(src, "regreet.css.in")).read())) | {"background"}
try:
    scheme = json.load(open(os.path.join(state, "caelestia/scheme.json")))
    # each one six hex digits: they go into hyprland.lua ("0xff...") and regreet.css as they are
    if not all(isinstance(scheme["colours"].get(c), str) and re.fullmatch(r"[0-9A-Fa-f]{6}", scheme["colours"][c])
               for c in needed):
        raise ValueError
except (OSError, ValueError, KeyError, TypeError, AttributeError):
    scheme = json.load(open(os.path.join(src, "default-scheme.json")))
    print("no complete colour scheme yet: using a neutral dark one")
dark = scheme.get("mode", "dark") == "dark"
colours = scheme["colours"]

# Monitors: the hl.monitor rules of the session's monitors.lua (Nexus > Display saves it). caelestia4: never copied as
# Lua: the file is the user's to write (any process running as them can), and this one runs as greeter at every boot.
# Each rule is parsed into its fields (monitors-save.py's parser, which skips comments and strings), each field is
# allow-listed by name and value, and the rule is written again from those values, strings Lua-escaped
sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("monitors_save", os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "../dots/.config/quickshell/ii/scripts/caelestia4/monitors-save.py"))
monitors_save = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(monitors_save)

NUMBER = r"-?\d+(?:\.\d+)?"
SELECTOR = r"[A-Za-z0-9._:-]*|desc:[^\x00-\x1f\x7f]+"  # a connector name ("" is every screen), or desc:<description>
# field: (Lua type, allowed value). A string's value is checked unescaped; numbers and booleans as written
MONITOR_FIELDS = {
    "output": ("string", SELECTOR), "mirror": ("string", SELECTOR),
    "mode": ("string", r"preferred|highrr|highres|maxwidth|\d+x\d+(?:@\d+(?:\.\d+)?)?"),
    "position": ("string", r"auto(?:-(?:left|right|up|down|center-left|center-right|center-up|center-down))?|-?\d+x-?\d+"),
    "scale": ("number", NUMBER), "transform": ("number", r"[0-7]"), "disabled": ("boolean", r"true|false"),
    "vrr": ("number", r"[0-3]"), "bitdepth": ("number", r"8|10"), "cm": ("string", r"[a-z0-9]+"),
    "sdrbrightness": ("number", NUMBER), "sdrsaturation": ("number", NUMBER),
    "sdr_min_luminance": ("number", NUMBER), "sdr_max_luminance": ("number", NUMBER),
    "min_luminance": ("number", NUMBER), "max_luminance": ("number", NUMBER), "max_avg_luminance": ("number", NUMBER),
    "supports_wide_color": ("number", r"-?[01]"), "supports_hdr": ("number", r"-?[01]"),
}


def lua_string(value):
    """A Lua string literal ("...") as its value, or None: only \\ and \" escapes, nothing else Lua would read"""
    m = re.fullmatch(r'\s*"((?:[^"\\\n]|\\["\\])*)"\s*', value)
    return re.sub(r"\\(.)", r"\1", m.group(1)) if m else None


def monitor_rule(fields):
    """The rule written again from its allow-listed fields, or None (no output, or an output or mode that isn't one)"""
    out = []
    for key, raw in fields.items():
        if key not in MONITOR_FIELDS:
            print(f"monitors.lua: a field the greeter doesn't take is left out ({key[:20]!r})")
            continue
        kind, allowed = MONITOR_FIELDS[key]
        value = lua_string(raw) if kind == "string" else raw.strip()
        if value is None or not re.fullmatch(allowed, value):
            if key in ("output", "mode"):
                return None
            print(f"monitors.lua: {key} isn't a value the greeter takes: left out")
            continue
        out.append(f'    {key} = "{monitors_save.lua(value)}",' if kind == "string" else f"    {key} = {value},")
    if not any(line.startswith("    output = ") for line in out):
        return None
    return "hl.monitor({\n" + "\n".join(out) + "\n})"


try:
    mon = open(os.path.join(cfg, "hypr/monitors.lua"), encoding="utf-8", errors="surrogateescape").read()
except OSError:  # none saved yet: Hyprland's defaults
    mon = ""
rules = [monitor_rule(fields) for _, fields in monitors_save.rules(mon)]
if None in rules:
    print(f"monitors.lua: {rules.count(None)} rule(s) without a plain output and mode left out")
monitors = "\n".join(r for r in rules if r) or 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })'

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
# Layout names only (us, de,fr, gb+intl): it goes into hyprland.lua's kb_layout = "..."
if not isinstance(layout, str) or not re.fullmatch(r"[A-Za-z0-9_,+-]+", layout):
    layout = "us"
# A locale name (en_US, vi_VN, sr_RS@latin), else en_US: it goes into regreet.toml
locale = (os.environ.get("LC_TIME") or os.environ.get("LANG") or "en_US.UTF-8").split(".")[0]
if not re.fullmatch(r"[A-Za-z]{2,3}(_[A-Za-z]{2})?(@[A-Za-z0-9]+)?", locale):
    locale = "en_US"

# Wallpaper: end-4's path, or its first-frame thumbnail for a video
try:
    shell_config = json.load(open(os.path.join(cfg, "illogical-impulse/config.json")))
    shell_config = shell_config if isinstance(shell_config, dict) else {}
except (OSError, ValueError):
    shell_config = {}
bg = shell_config.get("background") or {}
bg = bg if isinstance(bg, dict) else {}
wall = bg.get("wallpaperPath", "")
wall = wall if isinstance(wall, str) else ""
if re.search(r"\.(mp4|webm|mkv|avi|mov)$", wall, re.I):
    wall = bg.get("thumbnailPath", "")
    wall = wall if isinstance(wall, str) else ""
# Only an extension of letters and digits names the copy (/etc/greetd/background.<ext>): anything else, no background
ext = os.path.splitext(wall)[1].lower() or ".png"
bg_path = f"/etc/greetd/background{ext}"
if wall and re.fullmatch(r"\.[a-z0-9]{1,5}", ext) and os.path.isfile(wall):
    shutil.copyfile(wall, os.path.join(out, f"background{ext}"))
else:
    if wall:
        print("the wallpaper isn't a file with a usual extension: no background")
    bg_path = ""


def fill(name, values):
    text = open(os.path.join(src, name)).read()
    for k, v in values.items():
        text = text.replace(f"@{k}@", v)
    left = re.findall(r"@[A-Z_]+@", text)
    assert not left, f"{name}: unfilled {left}"
    return text


def toml_inner(s):
    """s as the inside of a TOML basic string ("..."): backslash, quote and every control character escaped"""
    return "".join(
        "\\\\" if c == "\\" else '\\"' if c == '"' else f"\\u{ord(c):04X}" if ord(c) < 0x20 or ord(c) == 0x7F else c
        for c in s)


open(os.path.join(out, "hyprland.lua"), "w").write(fill("hyprland.lua.in", {
    "MONITORS": monitors, "BACKGROUND": colours["background"], "KB_LAYOUT": layout}))
# In the shell's language (its catalogue), else the locale's. Only a language name: it's part of a file path
language = shell_config.get("language")
ui = language.get("ui", "auto") if isinstance(language, dict) else "auto"
if ui == "auto":
    ui = (os.environ.get("LC_MESSAGES") or os.environ.get("LANG") or "").split(".")[0]
if not isinstance(ui, str) or not re.fullmatch(r"[A-Za-z_]+", ui):
    ui = ""
try:
    catalogue = json.load(open(os.path.join(src, "../../dots/.config/quickshell/ii/translations", f"{ui}.json"))) if ui else {}
    catalogue = catalogue if isinstance(catalogue, dict) else {}
except (OSError, ValueError):
    catalogue = {}


def tr(text):
    value = catalogue.get(text)
    return (value if isinstance(value, str) and value else text).removesuffix("/*keep*/").strip()


# Every value is inside "..." in the template (DATE_FORMAT inside a longer string), so each is escaped for that
regreet = fill("regreet.toml.in", {k: toml_inner(v) for k, v in {
    "GREETING": tr("Welcome back!"),
    # with words of its own only in the clock's locale: weekday and month names come from that
    "DATE_FORMAT": tr("%A, %d %B") if ui.split("_")[0] == locale.split("_")[0] else "%A, %d %B",
    "BACKGROUND_PATH": bg_path, "DARK_SUFFIX": "-dark" if dark else "",
    "ICON_THEME": "breeze-dark" if dark else "breeze", "LOCALE": locale}.items()} | {"DARK": "true" if dark else "false"})
# The same tables as the template, nothing more: ReGreet hands an [env] table to every session it logs in
template = tomllib.loads(re.sub(r"@[A-Z_]+@", "x", open(os.path.join(src, "regreet.toml.in")).read()).replace("= x\n", "= true\n"))
try:
    parsed = tomllib.loads(regreet)
except tomllib.TOMLDecodeError as e:
    sys.exit(f"regreet.toml doesn't parse ({e}): nothing was installed")
if set(parsed) != set(template) or "env" in parsed:
    sys.exit(f"regreet.toml has tables the template hasn't ({sorted(set(parsed) ^ set(template))}): nothing was installed")
open(os.path.join(out, "regreet.toml"), "w").write(regreet)
config_in = open(os.path.join(src, "config.toml")).read()
# The GPU the session uses (two-GPU machines: the monitors are on this one). Only /dev/dri paths, ':' between them:
# it goes into the command greetd runs as root's config, inside a TOML string
if aq and not re.fullmatch(r"/dev/dri/[A-Za-z0-9._-][A-Za-z0-9._/-]*(:/dev/dri/[A-Za-z0-9._-][A-Za-z0-9._/-]*)*", aq):
    print("AQ_DRM_DEVICES isn't a list of /dev/dri paths: the greeter uses the default GPU")
    aq = ""
config = config_in.replace("env AQ_DRM_DEVICES=@AQ_DRM_DEVICES@ ", f"env AQ_DRM_DEVICES={aq} " if aq else "")
# The template's tables and keys, nothing more (an [initial_session] would log someone in with no password)
try:
    parsed = tomllib.loads(config)
except tomllib.TOMLDecodeError as e:
    sys.exit(f"config.toml doesn't parse ({e}): nothing was installed")
template = tomllib.loads(config_in)
command = parsed.get("default_session", {}).get("command", "")
if ({t: set(v) for t, v in parsed.items()} != {t: set(v) for t, v in template.items()} or parsed["terminal"] != template["terminal"]
        or parsed["default_session"]["user"] != template["default_session"]["user"]
        or command != re.sub(r"env AQ_DRM_DEVICES=\S* ", f"env AQ_DRM_DEVICES={aq} " if aq else "", template["default_session"]["command"])):
    sys.exit("config.toml isn't the template's with the GPU filled in: nothing was installed")
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
shown = re.sub(r"[\x00-\x1f\x7f]", "?", os.path.basename(wall)) if bg_path else "none"
print(f"monitors: {monitors.count('hl.monitor')}, layout: {layout}, clock: {locale}, mode: {'dark' if dark else 'light'}, "
      f"background: {shown}, GPU: {aq or 'default'}")

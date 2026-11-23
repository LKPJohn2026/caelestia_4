#!/usr/bin/env python3
"""caelestia4: checks that tools/greetd-gen.py (the files tools/greetd-setup.sh installs as root) escapes what it
puts in regreet.toml, so nothing from a wallpaper's name, the locale or a translation becomes TOML of its own (an
[env] table: ReGreet hands it to every session it logs in).

  python3 -I tools/tests/greetd-gen/run.py

A copy of dots-extra/greetd and a translations folder in a temporary directory, a fake HOME, stub hyprctl and
localectl. Never runs sudo, installs nothing, touches nothing outside that directory.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
GEN = REPO / "tools/greetd-gen.py"
failures = []


def check(ok, what):
    print(f"  {'ok  ' if ok else 'FAIL'} {what}")
    if not ok:
        failures.append(what)


def run(root, wall, env_extra, ui="xx_XX", catalogue=None, aq="", hyprctl='{"str": "us"}', localectl="", scheme=None,
        monitors=None):
    """greetd-gen.py on a fresh fake HOME; returns (exit code, output, regreet.toml parsed or None, OUT)"""
    case = Path(tempfile.mkdtemp(dir=root))
    home, out, stubs = case / "home", case / "out", case / "stubs"
    for d in (home / ".config/illogical-impulse", out, stubs):
        d.mkdir(parents=True)
    (stubs / "hyprctl.out").write_text(hyprctl + "\n")
    (stubs / "localectl.out").write_text(localectl + "\n")
    (stubs / "hyprctl").write_text(f"#!/bin/sh\ncat '{stubs}/hyprctl.out'\n")
    (stubs / "localectl").write_text(f"#!/bin/sh\ncat '{stubs}/localectl.out'\n")
    if scheme is not None:
        (home / ".local/state/caelestia").mkdir(parents=True)
        (home / ".local/state/caelestia/scheme.json").write_text(json.dumps(scheme))
    if monitors is not None:
        (home / ".config/hypr").mkdir(parents=True)
        (home / ".config/hypr/monitors.lua").write_text(monitors)
    for s in ("hyprctl", "localectl"):
        (stubs / s).chmod(0o755)
    (home / ".config/illogical-impulse/config.json").write_text(
        json.dumps({"background": {"wallpaperPath": wall}, "language": {"ui": ui}}))
    src = root / "tree/dots-extra/greetd"
    if catalogue is not None:
        (root / "tree/dots/.config/quickshell/ii/translations/xx_XX.json").write_text(json.dumps(catalogue))
    env = {"PATH": f"{stubs}:/usr/bin:/bin", "HOME": str(home), "LANG": "en_US.UTF-8", **env_extra}
    p = subprocess.run([sys.executable, "-I", str(GEN), str(src), str(out), str(home / ".config"),
                        str(home / ".local/state"), aq], env=env, capture_output=True, text=True)
    toml = out / "regreet.toml"
    try:
        parsed = tomllib.loads(toml.read_text()) if toml.exists() else None
    except tomllib.TOMLDecodeError:
        parsed = None
    return p.returncode, p.stdout + p.stderr, parsed, out


root = Path(tempfile.mkdtemp(prefix="c4greetdtest."))
try:
    shutil.copytree(REPO / "dots-extra/greetd", root / "tree/dots-extra/greetd")
    (root / "tree/dots/.config/quickshell/ii/translations").mkdir(parents=True)
    shutil.copy(REPO / "dots/.config/quickshell/ii/translations/vi_VN.json",
                root / "tree/dots/.config/quickshell/ii/translations/vi_VN.json")
    template = set(tomllib.loads((REPO / "dots-extra/greetd/regreet.toml.in").read_text()
                                 .replace("= @DARK@", "= true")))
    walls = root / "walls"
    walls.mkdir()

    print("== a normal run")
    good = walls / "nice.JPG"
    good.write_bytes(b"\xff\xd8\xff")
    code, log, t, out = run(root, str(good), {"LC_TIME": "vi_VN.UTF-8"}, ui="vi_VN")
    check(code == 0 and t is not None, f"it runs and writes regreet.toml ({log.strip()[-200:]})")
    if t:
        check(set(t) == template, "the template's tables, no others")
        check(t["background"]["path"] == "/etc/greetd/background.jpg", "the background is the wallpaper's copy")
        check((out / "background.jpg").exists(), "the wallpaper is copied")
        check(t["appearance"]["greeting_msg"] == "Chào mừng trở lại!", "the greeting is the Vietnamese one")
        check(t["widget"]["clock"]["locale"] == "vi_VN", "the clock's locale is vi_VN")
        check("%A, %d tháng %m" in t["widget"]["clock"]["format"], "the date format is the Vietnamese one")

    print("== a wallpaper whose name breaks out of the string")
    bad = walls / 'nice.x"\n[env]\n"\\u004c\\u0044_PRELOAD" = "\\u002ftmp\\u002fevil"\nz = "'
    bad.write_bytes(b"\x89PNG\r\n\x1a\n")
    code, log, t, out = run(root, str(bad), {})
    check(code == 0 and t is not None and "env" not in t and set(t) == template, "no [env], the template's tables")
    check(t is not None and t["background"]["path"] == "", "no background (not a picture's extension)")
    check(not any(out.glob("background*")), "nothing copied")
    bad2 = walls / 'a"\n[env]\nX = "1\n#.png'
    bad2.write_bytes(b"\x89PNG\r\n\x1a\n")
    code, log, t, out = run(root, str(bad2), {})
    check(t is not None and "env" not in t and t["background"]["path"] == "/etc/greetd/background.png",
          "a quote and line breaks before .png: the copy's own name only")

    print("== the locale and the language")
    code, log, t, _ = run(root, "", {"LANG": 'en_US"\n[env]\nX = "1\n#', "LC_TIME": ""}, ui="auto")
    check(code == 0 and t is not None and "env" not in t and t["widget"]["clock"]["locale"] == "en_US",
          "a LANG with a quote and line breaks: en_US")
    code, log, t, _ = run(root, "", {}, ui="../../../../../etc/x")
    check(code == 0 and t is not None and t["appearance"]["greeting_msg"] == "Welcome back!",
          "a language name with ../ isn't a path: English")

    print("== a translation that breaks out of the string")
    payload = 'Hi"\n[env]\nLD_PRELOAD = "/tmp/e"\nz = "\\'
    code, log, t, _ = run(root, "", {"LC_TIME": "xx_XX.UTF-8"}, catalogue={
        "Welcome back!": payload, "%A, %d %B": '%A"\n[env]\nY = "2'})
    check(code == 0 and t is not None and "env" not in t and set(t) == template, "no [env], the template's tables")
    check(t is not None and t["appearance"]["greeting_msg"] == payload.strip(), "the greeting is the text as it is")

    print("== the GPU in config.toml (root's greetd runs its command)")
    code, log, t, out = run(root, "", {}, aq="/dev/dri/nvidia-dgpu")
    cfg = tomllib.loads((out / "config.toml").read_text()) if (out / "config.toml").exists() else {}
    check(code == 0 and cfg.get("default_session", {}).get("command", "").startswith(
        "env AQ_DRM_DEVICES=/dev/dri/nvidia-dgpu Hyprland "), "a /dev/dri path is set in the command")
    hostile = 'x Hyprland -c /etc/greetd/hyprland.lua"\n[initial_session]\ncommand = "/bin/sh -c id #'
    for aq in (hostile, "/dev/dri/card1; id", '/dev/dri/x"\n[initial_session]\nuser = "root'):
        code, log, t, out = run(root, "", {}, aq=aq)
        text = (out / "config.toml").read_text() if (out / "config.toml").exists() else ""
        cfg = tomllib.loads(text) if text else {}
        check(code == 0 and set(cfg) == {"terminal", "default_session"} and "initial_session" not in text
              and cfg["default_session"]["command"].startswith("Hyprland -c ")
              and cfg["default_session"]["user"] == "greeter",
              f"AQ_DRM_DEVICES {aq[:24]!r}...: dropped, the template's tables only")

    print("== the keyboard layout and the colours in hyprland.lua and regreet.css")
    code, log, t, out = run(root, "", {}, hyprctl='{"str": ""}', localectl='   X11 Layout: us"},os.execute("id"),{x="')
    lua = (out / "hyprland.lua").read_text() if (out / "hyprland.lua").exists() else ""
    check(code == 0 and 'kb_layout = "us",' in lua and "os.execute" not in lua, "a layout with Lua in it: us")
    code, log, t, out = run(root, "", {}, hyprctl='{"str": "de,fr"}')
    check('kb_layout = "de,fr",' in ((out / "hyprland.lua").read_text() if (out / "hyprland.lua").exists() else ""),
          "a real layout list is kept")
    good_scheme = json.loads((REPO / "dots-extra/greetd/default-scheme.json").read_text())
    evil = json.loads(json.dumps(good_scheme))
    evil["colours"]["background"] = '000000",os.execute("id"),x="'
    evil["colours"]["primary"] = "fff; } * { background: url(http://e/) } x {"
    code, log, t, out = run(root, "", {}, scheme=evil)
    lua = (out / "hyprland.lua").read_text() if (out / "hyprland.lua").exists() else ""
    css = (out / "regreet.css").read_text() if (out / "regreet.css").exists() else ""
    check(code == 0 and "os.execute" not in lua and "url(" not in css
          and f'0xff{good_scheme["colours"]["background"]}' in lua, "colours that aren't hex: the neutral scheme")
    mine = json.loads(json.dumps(good_scheme))
    mine["colours"]["background"] = "0A0B0C"
    code, log, t, out = run(root, "", {}, scheme=mine)
    check("0xff0A0B0C" in ((out / "hyprland.lua").read_text() if (out / "hyprland.lua").exists() else ""),
          "a hex scheme is used")

    print("== the monitors in hyprland.lua (the greeter runs it at every boot)")
    # built here, so no mode or connector name is written in the repo (tools/lint-monitors.sh)
    w, h, r = 2000, 1000, 75
    mode = f"{w}x{h}@{r}"
    desc = "desc" + ':Maker \\"Q\\" X'  # a description with escaped quotes, as Lua source
    hostile_mon = "\n".join([
        "-- a comment",
        'hl.monitor({ output = os.execute("touch /tmp/greeter-pwned") and "" or "", mode = "preferred", '
        'position = "auto", scale = 1 })',
        f'hl.monitor({{ output = "screen-a", mode = "{mode}", position = "0x0", scale = 1.5, transform = 0, '
        'vrr = (function() os.execute("id") return 1 end)(), bitdepth = 10 })',
        f'hl.monitor({{ output = "screen-b", mode = "{mode}" .. io.popen("id"):read("a"), position = "auto" }})',
        f'hl.monitor({{ output = "{desc}", mode = "preferred", position = "-100x0", scale = 1, '
        'cm = "hdr", load = dofile("/tmp/x") })',
        'hl.monitor({ output = [[screen-c]], mode = "preferred" })',
        'os.execute("id")',
    ])
    code, log, t, out = run(root, "", {}, monitors=hostile_mon)
    lua = (out / "hyprland.lua").read_text() if (out / "hyprland.lua").exists() else ""
    check(code == 0 and lua, f"it runs with Lua in monitors.lua ({log.strip()[-200:]})")
    for bad_text in ("os.execute", "io.popen", "dofile", "return 1 end", "greeter-pwned", "[[", "a comment"):
        check(bad_text not in lua, f"{bad_text!r} isn't in hyprland.lua")
    check(f'output = "screen-a",\n    mode = "{mode}",\n    position = "0x0",\n    scale = 1.5,\n    transform = 0,'
          '\n    bitdepth = 10,' in lua, "a plain rule is written again field by field, a Lua vrr left out")
    check('"screen-b"' not in lua, "a rule whose mode is an expression is left out")
    check(f'output = "{desc}",' in lua and 'position = "-100x0",' in lua and 'cm = "hdr",' in lua,
          "a desc: output keeps its escaped quotes, an unknown field is left out")
    check(lua.count("hl.monitor(") == 2, "only the two plain rules")
    if shutil.which("luac") or shutil.which("luac5.4"):
        luac = shutil.which("luac5.4") or shutil.which("luac")
        check(subprocess.run([luac, "-p", str(out / "hyprland.lua")], capture_output=True).returncode == 0,
              "hyprland.lua parses")
    code, log, t, out = run(root, "", {}, monitors='hl.monitor({ output = os.execute("id") })')
    lua = (out / "hyprland.lua").read_text() if (out / "hyprland.lua").exists() else ""
    check(code == 0 and "os.execute" not in lua and 'output = "", mode = "preferred"' in lua,
          "no plain rule at all: Hyprland's defaults")

    print("== other picture formats")
    jxl = walls / "x.jxl"
    jxl.write_bytes(b"\xff\x0a")
    code, log, t, out = run(root, str(jxl), {})
    check(t is not None and t["background"]["path"] == "/etc/greetd/background.jxl"
          and (out / "background.jxl").exists(), "a .jxl wallpaper is the background")
finally:
    shutil.rmtree(root, ignore_errors=True)

if failures:
    print(f"greetd-gen tests: {len(failures)} FAILED")
    sys.exit(1)
print("greetd-gen tests: OK")

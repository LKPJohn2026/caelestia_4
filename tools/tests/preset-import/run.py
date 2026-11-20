#!/usr/bin/env python3
"""caelestia4: checks that preset-import.py takes only what a preset may set, from any repo.

  python3 -I tools/tests/preset-import/run.py [GALLERY_DIR...]

1. WIDGET_FIELDS (what a preset's widget may set) has the same fields, of the same kinds, as background.widgets in
   modules/common/Config.qml, so a field added to the shell isn't left out of every preset without anyone noticing.
   Each number with a range in WIDGET_FIELDS has the min and max of that field in Nexus's registry, and each number
   Nexus gives a range has one in WIDGET_FIELDS (a preset's cookie with a million sides would hang the shell).
2. The fixtures are applied for real, in a fake HOME with stub commands (hyprctl, qs, notify-send, gsettings, ...: they
   only log their arguments): fixtures/benign is taken whole; fixtures/malicious (commands, markup, shell characters,
   paths out of its folder, links to a file outside, NaN, a number too big for a float) is left out and said, and
   nothing of it reaches the config, the lock screen, ~/.face, the pictures or a command's arguments. A number out of
   its field's range is brought to the nearest end and said.
3. --sync on a fake clone with links in it (a wallpaper, a preset folder, a file in a preset, a sibling folder a preset
   could find pictures in, the presets folder itself): nothing a link points at reaches the library or Pictures.
4. Each GALLERY_DIR given (a folder of preset folders: the library, ~/.local/share/caelestia4/presets, or a clone of
   pctrade/end4-pCpresets/presets, read only) is checked: a real preset must lose no value, only fields this shell
   hasn't got (and no number brought into its range).

Never touches the desktop, the real HOME or the network.
"""
import importlib.util
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
SCRIPT = REPO / "dots/.config/quickshell/ii/scripts/presets/preset-import.py"
CONFIG_QML = REPO / "dots/.config/quickshell/ii/modules/common/Config.qml"
REGISTRY = REPO / "dots/.config/quickshell/ii/modules/caelestia/nexus/registry"
STUBS = ("hyprctl", "qs", "notify-send", "gsettings", "xdg-user-dir", "magick", "ffmpeg", "gh", "curl", "git")
PNG = b"\x89PNG\r\n\x1a\n"

failures = []


def check(ok, what):
    print(f"  {'ok  ' if ok else 'FAIL'} {what}")
    if not ok:
        failures.append(what)


def sandbox():
    """A fake HOME and the environment that points the script into it (and stub commands first in PATH)"""
    root = Path(tempfile.mkdtemp(prefix="c4presettest."))
    home = root / "home"
    env = {"HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"), "XDG_STATE_HOME": str(home / ".local/state"),
           "XDG_DATA_HOME": str(home / ".local/share"), "XDG_CACHE_HOME": str(home / ".cache"),
           "PRESET_IMPORT_PICTURES": str(home / "Pictures"), "PRESET_IMPORT_FACE": str(home / ".face"),
           "LANG": "C.UTF-8"}
    stubs = root / "stubs"
    stubs.mkdir(parents=True)
    log = root / "commands.log"
    for name in STUBS:
        (stubs / name).write_text(f'#!/bin/sh\nprintf "%s\\0" {name} "$@" >> "{log}"\nprintf "\\n" >> "{log}"\n')
        (stubs / name).chmod(0o755)
    env["PATH"] = f"{stubs}:/usr/bin:/bin"
    (home / ".config/illogical-impulse").mkdir(parents=True)
    (home / ".config/illogical-impulse/config.json").write_text('{"apps": {"terminal": "kitty"}}\n')
    return root, home, env, log


def load_module(env):
    for k, v in env.items():
        os.environ[k] = v
    sys.dont_write_bytecode = True  # no __pycache__ in the dots
    spec = importlib.util.spec_from_file_location("preset_import", SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def config_widgets():
    """{widget: {field: QML type, or {...} for a JsonObject}} from background.widgets in Config.qml"""
    lines = CONFIG_QML.read_text(encoding="utf-8").splitlines()
    start = next(i for i, line in enumerate(lines) if re.search(r"property JsonObject widgets: JsonObject \{", line))
    stack, depth = [{}], 1
    root = stack[0]
    for line in lines[start + 1:]:
        code = line.split("//", 1)[0]
        if m := re.search(r"property JsonObject (\w+): JsonObject \{", code):
            stack[-1][m.group(1)] = {}
            stack.append(stack[-1][m.group(1)])
            depth += 1
            if "}" in code.split("{", 1)[1]:  # all on one line
                stack.pop()
                depth -= 1
            continue
        if m := re.search(r"property ([\w<>]+) (\w+):", code):
            stack[-1][m.group(2)] = m.group(1)
        depth -= code.count("}") - code.count("{")
        for _ in range(code.count("}") - code.count("{")):
            stack.pop()
        if depth <= 0:
            break
    return root


KINDS = {"bool": {"bool"}, "real": {"num"}, "int": {"num"}, "string": {"name", "color", "text", "picture"},
         "list<string>": {"zones"}}


def compare(fields, qml, where):
    for k in sorted(set(fields) | set(qml)):
        f, q = fields.get(k), qml.get(k)
        f = f[0] if isinstance(f, tuple) else f
        if isinstance(f, dict) or isinstance(q, dict):
            if isinstance(f, dict) and isinstance(q, dict):
                compare(f, q, f"{where}.{k}")
            else:
                check(False, f"{where}.{k}: an object in one of WIDGET_FIELDS and Config.qml only")
        elif f is None or q is None:
            check(False, f"{where}.{k}: in {'Config.qml' if f is None else 'WIDGET_FIELDS'} only")
        elif f not in KINDS.get(q, set()):
            check(False, f"{where}.{k}: {f} in WIDGET_FIELDS, {q} in Config.qml")


def test_schema(mod):
    print("== WIDGET_FIELDS against Config.qml")
    qml = config_widgets()
    before = len(failures)
    check(set(mod.WIDGETS) == set(mod.WIDGET_FIELDS), "every widget a preset may set has its fields listed")
    for key in mod.WIDGETS:
        if key not in qml:
            check(False, f"{key}: not in Config.qml's background.widgets")
            continue
        compare(mod.WIDGET_FIELDS.get(key, {}), qml[key], key)
    if len(failures) == before:
        check(True, f"{len(mod.WIDGETS)} widgets, the same fields and kinds")


def registry_ranges():
    """{"clock.cookie.sides": (min, max), ...}: the e4:background.widgets.* entries of Nexus's registry with both"""
    ranges = {}
    for qml in sorted(REGISTRY.glob("*.qml")):
        key, lo, hi = None, None, None
        for line in qml.read_text(encoding="utf-8").splitlines() + ['"e4:end": {']:
            if m := re.search(r'"(?:e4|c4|[a-z]+):([\w.]+)":\s*\{', line):
                if key and lo is not None and hi is not None:
                    ranges[key] = (lo, hi)
                full = m.group(1)
                key = full[len("background.widgets."):] if full.startswith("background.widgets.") else None
                lo = hi = None
            elif key and (m := re.match(r"\s*(min|max):\s*(-?[\d.]+)\s*,?\s*$", line)):
                n = float(m.group(2))
                n = int(n) if n.is_integer() else n
                lo, hi = (n, hi) if m.group(1) == "min" else (lo, n)
    return ranges


def num_fields(fields, where=""):
    for k, kind in fields.items():
        if isinstance(kind, dict):
            yield from num_fields(kind, f"{where}{k}.")
        elif kind == "num" or isinstance(kind, tuple):
            yield f"{where}{k}", kind


def test_ranges(mod):
    print("== number ranges against Nexus's registry")
    reg = registry_ranges()
    check(reg.get("clock.cookie.sides") == (3, 40), "the registry is read (clock.cookie.sides is 3 to 40 there)")
    before, n = len(failures), 0
    for key in mod.WIDGETS:
        for field, kind in num_fields(mod.WIDGET_FIELDS.get(key, {})):
            path, have = f"{key}.{field}", reg.get(f"{key}.{field}")
            if isinstance(kind, tuple):
                n += 1
                if kind[1:] != have:
                    check(False, f"{path}: {kind[1]} to {kind[2]} in WIDGET_FIELDS, {have} in the registry")
            elif have:
                check(False, f"{path}: no range in WIDGET_FIELDS, {have[0]} to {have[1]} in the registry")
    if len(failures) == before:
        check(n > 0, f"{n} numbers with a range, each the registry's")


def test_values(mod):
    print("== values")
    good = [("bool", False), ("num", -12.5), ("num", 0), ("name", "Cookie4Sided"), ("color", ""), ("color", "#ffffff"),
            ("color", "primary"), ("text", "Rock & roll, 1 < 2\nsecond line"), ("text", "a > b, b < c"),
            ("zones", ["Etc/GMT+5", "UTC"])]
    bad = [("bool", 1), ("bool", "true"), ("num", True), ("num", "10"), ("num", math.nan), ("num", math.inf),
           ("num", 1e300), ("num", 10**400), ("num", -10**400), ("name", ["x"]), ("name", "a\nb"), ("name", "x" * 201),
           ("color", "red; rm -rf ~"), ("color", "$(id)"), ("text", "<img src=\"https://x.invalid/p.png\">"),
           ("text", "<a href=x>"), ("text", "&lt; < img src=\"https://x.invalid/p.png\">"),
           ("text", "x\n<\timg src=\"https://x.invalid/p.png\">"), ("text", "< img src=x>"),
           ("text", "&#60;b&#62;"), ("text", "bell \x07"), ("zones", ["Asia/Tokyo'; id; '"]),
           ("zones", ["../../etc/passwd"]), ("zones", ["Asia/Tokyo"] * 9), ("zones", "Asia/Tokyo"), ("picture", 5),
           ("unknown", "x")]
    check(all(mod.good_value(k, v) for k, v in good), f"{len(good)} good values taken")
    taken = [(k, v) for k, v in bad if mod.good_value(k, v)]
    check(not taken, f"{len(bad)} bad values refused" + (f" (taken: {taken})" if taken else ""))
    entry, dropped, moved = mod.clean_widget("clock", {"enable": True, "command": "id", "cookie": "x",
                                                       "quote": {"text": "hi", "exec": "id"}})
    check(entry == {"enable": True, "quote": {"text": "hi"}} and dropped == ["clock.cookie"] and not moved,
          "clean_widget keeps the known fields, drops unknown ones quietly and says the bad ones")
    # the finding's preset: a cookie of a million sides (RoundedPolygon.star would build two million vertices)
    entry, dropped, moved = mod.clean_widget("clock", {"enable": True, "style": "cookie",
                                                       "cookie": {"sides": 10**6, "useSineCookie": False}})
    check(entry["cookie"] == {"sides": 40, "useSineCookie": False} and not dropped
          and moved == ["clock.cookie.sides (1000000 is outside 3 to 40: 40 instead)"],
          "a million cookie sides brought down to 40, and said")
    entry, _, moved = mod.clean_widget("clock", {"cookie": {"sides": -5}, "x": -5})
    check(entry == {"cookie": {"sides": 3}, "x": -5} and len(moved) == 1, "-5 sides brought up to 3, a place left as it is")
    edge = {"enable": True, "size": 60, "rotation": -180, "outlineWidth": 24}
    entry, dropped, moved = mod.clean_widget("sticker", edge)
    check(entry == edge and not dropped and not moved, "a sticker at its ends of every range kept as it is")
    entry, _, moved = mod.clean_widget("visualizer", {"sensitivity": 0.1, "height": 4000, "ringSize": 20})
    check(entry == {"sensitivity": 0.3, "height": 600, "ringSize": 200} and len(moved) == 3,
          "visualizer numbers out of range brought to their ends")
    entry, dropped, moved = mod.clean_widget("worldClock", {"clockCount": math.nan, "x": 10**400})
    check(entry == {} and sorted(dropped) == ["worldClock.clockCount", "worldClock.x"] and not moved,
          "NaN and a number too big for a float still left out, not brought into range")


def run(env, *args):
    return subprocess.run([sys.executable, "-I", str(SCRIPT), *args], env=env, capture_output=True, text=True,
                          timeout=60, stdin=subprocess.DEVNULL)


def test_apply():
    print("== fixtures applied in a fake HOME")
    root, home, env, log = sandbox()
    try:
        presets = root / "presets"
        shutil.copytree(HERE / "fixtures", presets)
        for p in ("benign/wall.png", "benign/lock.jpg", "benign/avatar.png", "benign/cat.png"):
            (presets / p).write_bytes(PNG + p.encode())
        secret = root / "secret-key"
        secret.write_text("PRIVATE KEY\n")
        evil = presets / "malicious"
        for name in ("face.png", "secret.png"):  # links out of the preset's folder (names no other preset has)
            (evil / name).symlink_to(secret)
        doc = json.loads((evil / "malicious.json").read_text())
        doc["background"]["widgets"]["clock"]["z"] = math.nan  # json.load reads NaN; the config must never get one
        doc["background"]["widgets"]["worldClock"]["clockCount"] = 10**400  # an int no float can hold
        (evil / "malicious.json").write_text(json.dumps(doc))

        r = run(env, str(presets / "benign"))
        check(r.returncode == 0, f"benign applies (exit {r.returncode}){': ' + r.stderr.strip() if r.returncode else ''}")
        ii = json.loads((home / ".config/illogical-impulse/config.json").read_text())
        w = ii["background"]["widgets"]
        check(w["clock"]["quote"]["text"] == "Rock & roll, 1 < 2\nsecond line" and w["clock"]["x"] == 120.5
              and w["clock"]["cookie"]["sides"] == 12 and w["clock"]["digital"]["font"]["weight"] == 350,
              "benign: the clock, its quote and nested settings taken")
        check(w["worldClock"]["timezones"][0] == "Asia/Ho_Chi_Minh" and len(w["worldClock"]["timezones"]) == 4,
              "benign: the world clock's time zones taken")
        check(w["customImage"]["path"].endswith("/Pictures/Wallpapers/presets/benign/cat.png")
              and w["sticker"]["path"] == w["customImage"]["path"], "benign: pictures found by name in its folder")
        check("items" not in w["sticker"] and "endFourPcOnly" not in w, "benign: end4-pC-only fields left out")
        check(w["customText"]["content"] == "Hey, spaceboy, I'm not\ntalking to myself", "benign: text on two lines kept")
        check(w["sticker"]["outlineWidth"] == 8 and w["customText"]["fontSize"] == 72
              and w["worldClock"]["clockCount"] == 4, "benign: numbers in range kept as they are")
        check("(not a value this shell takes)" not in r.stdout and " instead)" not in r.stdout,
              "benign: nothing said to be left out or changed")
        check((home / ".face").read_bytes().endswith(b"benign/avatar.png"), "benign: avatar set")
        check("lock.jpg" in (home / ".config/hypr/hyprlock/lockwall.conf").read_text(), "benign: lock wallpaper set")

        log.unlink(missing_ok=True)
        (home / ".face").unlink()
        r = run(env, str(presets / "malicious"))
        out = r.stdout + r.stderr
        check(r.returncode == 0, f"malicious applies what's left (exit {r.returncode}){': ' + r.stderr.strip() if r.returncode else ''}")
        ii_text = (home / ".config/illogical-impulse/config.json").read_text()
        ii = json.loads(ii_text)
        w = ii["background"]["widgets"]
        check("PWNED" not in ii_text and "tracker.invalid" not in ii_text and "NaN" not in ii_text,
              "malicious: no command, URL or NaN in the config")
        check(ii["apps"] == {"terminal": "kitty"} and "autostart" not in ii and "hyprland" not in ii,
              "malicious: apps, autostart and Hyprland left alone")
        check(set(w["clock"]) == {"enable", "digital", "quote"} and w["clock"]["digital"] == {"font": {}}
              and w["clock"]["quote"] == {"enable": True}, "malicious: the clock's bad values left out")
        check("timezones" not in w["worldClock"] and "clockCount" not in w["worldClock"],
              "malicious: time zones with shell characters and a huge number left out")
        check("sizeMode" not in w["weather"] and "exec" not in w["weather"], "malicious: weather's object and exec left out")
        check(w["customImage"]["path"] == "" and w["sticker"]["path"] == "" and "outlineColor" not in w["sticker"],
              "malicious: no picture from a path out of its folder or with shell characters")
        check("content" not in w["customText"], "malicious: text with control characters left out")
        check(w["sticker"]["size"] == 800 and w["sticker"]["outlineWidth"] == 0 and w["customText"]["fontSize"] == 400,
              "malicious: a huge sticker, a negative outline and a huge font brought into range")
        for said in ("sticker.size (1000000 is outside 60 to 800: 800 instead)",
                     "sticker.outlineWidth (-5 is outside 0 to 24: 0 instead)",
                     "customText.fontSize (999999 is outside 12 to 400: 400 instead)"):
            check(said in out, f"malicious: {said.split(' ', 1)[0]} said to be brought into range")
        check(not (home / ".face").exists(), "malicious: a link to a file outside isn't the avatar")
        lockwall = (home / ".config/hypr/hyprlock/lockwall.conf").read_text()
        check("secret" not in lockwall and "$background_image" not in lockwall, "malicious: no lock wallpaper")
        pics = home / "Pictures/Wallpapers/presets/malicious"
        copied = [p for p in pics.rglob("*")] if pics.is_dir() else []
        check(not copied, f"malicious: no picture copied{' (' + ', '.join(map(str, copied)) + ')' if copied else ''}")
        leaked = [p for p in home.rglob("*") if p.is_file() and b"PRIVATE KEY" in p.read_bytes()]
        check(not leaked, "malicious: the file outside wasn't copied" + (f" ({', '.join(map(str, leaked))})" if leaked else ""))
        commands = log.read_bytes() if log.is_file() else b""
        check(b"PWNED" not in commands and b"secret" not in commands, "malicious: nothing of it in a command's arguments")
        for said in ("clock.x", "clock.y", "clock.z", "clock.color", "clock.cookie", "clock.quote.text",
                     "worldClock.timezones", "worldClock.clockCount", "weather.sizeMode", "sticker.outlineColor",
                     "customText.content"):
            check(f"{said} (not a value this shell takes)" in out, f"malicious: {said} said to be left out")
        check("command" not in out and "exec (" not in out, "malicious: unknown fields left out without a word")
        check(not any(root.rglob("PWNED")) and not Path("PWNED").exists(), "malicious: nothing ran")
    finally:
        shutil.rmtree(root, ignore_errors=True)


def test_sync():
    print("== --sync and apply on a fake clone with links in it")
    root, home, env, _ = sandbox()
    try:
        private = root / "private"  # stands for ~/Pictures/private, ~/.ssh, ...: outside the clone
        private.mkdir()
        (private / "secret.png").write_bytes(PNG + b"PRIVATE KEY")
        (private / "linked.json").write_text('{"background": {"widgets": {}}}')
        clone = root / "clone"
        (clone / "presets/good").mkdir(parents=True)
        (clone / "wall.png").write_bytes(PNG + b"wall")
        (clone / "secret.png").symlink_to(private / "secret.png")  # a wallpaper that is a link
        (clone / "wallpapers.json").write_text(json.dumps([{"filename": "wall.png"}, {"filename": "secret.png"}]))
        (clone / "presets/good/good.json").write_text('{"background": {"widgets": {}, "lockWall": "secret.png"}}')
        (clone / "presets/good/meta.json").write_text('{"avatar": "secret.png"}')
        (clone / "presets/good/preview.png").symlink_to(private / "secret.png")  # a file in a preset that is a link
        (clone / "presets/linked").symlink_to(private)  # a preset folder that is a link
        (clone / "presets/zz").symlink_to(private)  # a sibling folder apply looks for pictures in

        r = run(env, "--sync", str(clone))
        check(r.returncode == 0, f"--sync runs (exit {r.returncode}){': ' + r.stderr.strip() if r.returncode else ''}")
        library = home / ".local/share/caelestia4/presets"
        check((library / "good/good.json").is_file() and (home / "Pictures/Wallpapers/Blapples/wall.png").is_file(),
              "--sync: the clone's own preset and wallpaper copied")
        check(not (library / "linked").exists(), "--sync: a linked preset folder left out")
        check(not (library / "good/preview.png").exists(), "--sync: a linked file in a preset left out")
        check(not (home / "Pictures/Wallpapers/Blapples/secret.png").exists(), "--sync: a linked wallpaper left out")

        # applied straight from the clone: secret.png is in no folder of its own, only behind presets/zz and the
        # top-level link, and neither may be followed
        r = run(env, str(clone / "presets/good"))
        check(r.returncode == 0, f"apply from the clone runs (exit {r.returncode})")
        leaked = [p for p in home.rglob("*") if p.is_file() and b"PRIVATE KEY" in p.read_bytes()]
        check(not leaked, "apply from the clone: nothing behind a link copied"
              + (f" ({', '.join(map(str, leaked))})" if leaked else ""))

        clone2 = root / "clone2"
        clone2.mkdir()
        (clone2 / "presets").symlink_to(private)
        r = run(env, "--sync", str(clone2))
        check(r.returncode != 0 and not (library / "linked").exists(), "--sync: a presets folder that is a link refused")
    finally:
        shutil.rmtree(root, ignore_errors=True)


def test_gallery(mod, dirs):
    for d in dirs:
        print(f"== real presets in {d}")
        n, lost = 0, []  # a value left out, or a number brought into range
        for pdir in sorted(Path(d).iterdir()):
            js = mod.preset_json(pdir) if pdir.is_dir() else None
            if not js:
                continue
            try:
                doc = json.loads(js.read_text(encoding="utf-8"))
            except (OSError, ValueError) as e:
                lost.append(f"{pdir.name}: can't read it ({e})")
                continue
            n += 1
            widgets = (doc.get("background") or {}).get("widgets") or {}
            for key in mod.WIDGETS:
                if isinstance(widgets.get(key), dict):
                    _, bad, moved = mod.clean_widget(key, widgets[key])
                    lost += [f"{pdir.name}: {b}" for b in bad + moved]
        check(n > 0 and not lost, f"{n} presets, no value lost" + "".join(f"\n         {x}" for x in lost[:20]))


def main():
    root, _, env, _ = sandbox()
    try:
        mod = load_module(env)
        test_schema(mod)
        test_ranges(mod)
        test_values(mod)
    finally:
        shutil.rmtree(root, ignore_errors=True)
    test_apply()
    test_sync()
    test_gallery(mod, sys.argv[1:])
    print(f"preset-import tests: {'OK' if not failures else f'{len(failures)} FAILED'}")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""caelestia4: apply an end4-pC preset (github.com/pctrade/end4-pC presets, e.g. Blapples/wallpapers/presets/<name>).

A preset is end4-pC's whole config.json plus its pictures. Only what this shell can show is taken (a whitelist, so a
preset can't set commands like apps.*): the desktop widgets end4-pC and this shell share (pcwidgets: clock, weather,
calendar, media, custom image) at the preset's positions, the visualiser, the colour scheme type, the wallpaper, the
lock screen wallpaper and the avatar. The bar layout, AI, apps, Hyprland input and autostart are left alone.

Widget positions stay in the preset's 1920x1080 coordinates (background.widgets.canvas); each screen scales the room
around each widget to its own size, so widgets against an edge stay there on a 32:9 screen.

  tools/preset-import.py PRESET_DIR [--wallpapers DIR] [--dry-run]
  tools/preset-import.py --undo        put back the settings from before the last import

PRESET_DIR holds <name>.json and meta.json. The wallpapers named in meta.json are looked for in PRESET_DIR, then in
--wallpapers (default: two levels up, the root of a clone of Blapples/wallpapers).
"""
import argparse
import datetime
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
II_CONFIG = HOME / ".config/illogical-impulse/config.json"
SHELL_CONFIG = HOME / ".config/caelestia/shell.json"
LOCKWALL = HOME / ".config/hypr/hyprlock/lockwall.conf"
FACE = HOME / ".face"
STATE = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "caelestia4/preset-backups"
PICTURES = Path(subprocess.run(["xdg-user-dir", "PICTURES"], capture_output=True, text=True).stdout.strip() or HOME / "Pictures")

# end4-pC widgets this shell has (modules/caelestia/background/pcwidgets)
WIDGETS = ["clock", "weather", "calendar", "media", "customImage"]
# the size end4-pC presets are made on: their widget x / y are pixels on a 1920x1080 screen
PRESET_CANVAS = {"width": 1920, "height": 1080}
LOCKWALL_DEFAULT = "# caelestia4: a lock screen wallpaper of its own. Empty = the desktop wallpaper (colors.conf, from matugen).\n"


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def save(path, data):
    tmp = path.with_suffix(path.suffix + ".tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    os.replace(tmp, path)


def find_picture(name, dirs):
    for d in dirs:
        p = d / name
        if p.is_file():
            return p
    return None


def backup():
    dest = STATE / datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    dest.mkdir(parents=True)
    for src in (II_CONFIG, SHELL_CONFIG, LOCKWALL, FACE):
        if src.is_file():
            shutil.copy2(src, dest / src.name)
    return dest


def undo():
    backups = sorted(STATE.glob("*")) if STATE.is_dir() else []
    if not backups:
        sys.exit("no preset backup to restore")
    last = backups[-1]
    for dst in (II_CONFIG, SHELL_CONFIG, LOCKWALL, FACE):
        src = last / dst.name
        if src.is_file():
            shutil.copy2(src, dst)
        elif dst == LOCKWALL:
            dst.write_text(LOCKWALL_DEFAULT)
    wallpaper = load(II_CONFIG).get("background", {}).get("wallpaperPath")
    set_wallpaper(wallpaper)
    shutil.rmtree(last)
    print(f"restored the settings from {last.name}")


def set_wallpaper(path):
    # through the shell (Wallpapers.qml's IPC), so the colour scheme and hyprlock's colours follow
    if path and Path(path).is_file():
        subprocess.run(["qs", "-c", "ii", "ipc", "call", "wallpaper", "set", str(path)], check=False)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("preset", nargs="?", type=Path)
    ap.add_argument("--wallpapers", type=Path)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--undo", action="store_true")
    args = ap.parse_args()

    if args.undo:
        return undo()
    if not args.preset:
        ap.error("give a preset folder (or --undo)")

    pdir = args.preset.resolve()
    meta = load(pdir / "meta.json") if (pdir / "meta.json").is_file() else {}
    jsons = [p for p in pdir.glob("*.json") if p.name != "meta.json"]
    if len(jsons) != 1:
        sys.exit(f"{pdir}: expected one preset .json next to meta.json, found {len(jsons)}")
    preset = load(jsons[0])
    name = pdir.name
    search = [pdir, (args.wallpapers or pdir.parent.parent).resolve()]

    pbg = preset.get("background", {})
    pwidgets = pbg.get("widgets", {})
    applied, skipped = [], []

    # pictures: copied next to each other in Pictures/Wallpapers/presets/<name>
    out = PICTURES / "Wallpapers/presets" / name
    def picture(path_or_name):
        if not path_or_name:
            return None
        src = find_picture(Path(path_or_name).name, search)
        if not src:
            skipped.append(f"picture not found: {Path(path_or_name).name}")
            return None
        dst = out / src.name
        if not args.dry_run:
            out.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
        return dst

    for w in meta.get("wallpapers", []):
        picture(w)
    wallpaper = picture(pbg.get("wallpaperPath"))
    lockwall = picture(pbg.get("lockWall"))
    avatar = picture(meta.get("avatar") or preset.get("profile", {}).get("avatarPicture"))

    ii = load(II_CONFIG)
    widgets = ii.setdefault("background", {}).setdefault("widgets", {})
    widgets["canvas"] = dict(PRESET_CANVAS)
    for key in WIDGETS:
        if key not in pwidgets:
            widgets.setdefault(key, {})["enable"] = False
            continue
        entry = json.loads(json.dumps(pwidgets[key]))
        if key == "customImage":
            img = picture(meta.get("customImage") or entry.get("path"))
            entry["path"] = str(img) if img else ""
        widgets[key] = entry
        applied.append(f"widget {key}" + ("" if entry.get("enable") else " (off)"))
    for key in sorted(set(pwidgets) - set(WIDGETS) - {"visualizer"}):
        if isinstance(pwidgets[key], dict) and pwidgets[key].get("enable"):
            skipped.append(f"widget {key} (not ported)")

    palette = preset.get("appearance", {}).get("palette", {})
    if palette.get("type") and palette["type"] != "auto":
        ii.setdefault("appearance", {}).setdefault("palette", {})["type"] = palette["type"]
        applied.append(f"scheme {palette['type']}")

    shell = load(SHELL_CONFIG) if SHELL_CONFIG.is_file() else {}
    sbg = shell.setdefault("background", {})
    visualizer = pwidgets.get("visualizer", {}).get("enable")
    if visualizer is not None:
        sbg.setdefault("visualiser", {})["enabled"] = bool(visualizer)
        applied.append(f"visualiser {'on' if visualizer else 'off'}")
    if pwidgets.get("clock", {}).get("enable"):
        # one clock: the preset's, not Caelestia's desktop clock as well
        sbg.setdefault("desktopClock", {})["enabled"] = False
        applied.append("Caelestia desktop clock off")

    if wallpaper:
        applied.append(f"wallpaper {wallpaper.name}")
    if lockwall:
        applied.append(f"lock wallpaper {lockwall.name}")
    if avatar:
        applied.append(f"avatar {avatar.name}")
    skipped += ["bar layout, AI, apps, Hyprland options (not taken from presets)"]

    print(f"preset {name}:")
    for a in applied:
        print(f"  + {a}")
    for s in skipped:
        print(f"  - {s}")
    if args.dry_run:
        print("dry run: nothing changed")
        return

    print(f"backup: {backup()}  (undo: tools/preset-import.py --undo)")
    save(II_CONFIG, ii)
    save(SHELL_CONFIG, shell)
    if lockwall:
        LOCKWALL.write_text(LOCKWALL_DEFAULT + f"$background_image = {lockwall}\n")
    if avatar:
        shutil.copy2(avatar, FACE)
    set_wallpaper(wallpaper)


if __name__ == "__main__":
    main()

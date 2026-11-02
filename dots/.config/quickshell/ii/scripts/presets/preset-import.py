#!/usr/bin/env python3
"""caelestia4: apply an end4-pC preset (github.com/pctrade/end4-pC presets, e.g. Blapples/wallpapers/presets/<name>).

A preset is end4-pC's whole config.json plus its pictures. Only what this shell can show is taken (a whitelist, so a
preset can't set commands like apps.*): the desktop widgets end4-pC and this shell share (pcwidgets: clock, weather,
calendar, media, custom image, user card, world clock, resources, notes, timers, to-do, image converter) at the preset's positions, the visualiser, the colours
(style, accent colour, light / dark), the wallpaper, the lock screen wallpaper, the banner (on the user card) and the avatar. The bar layout, AI, apps, Hyprland input and autostart are left alone.

Widget positions stay in the preset's 1920x1080 coordinates (background.widgets.canvas); each screen scales the room
around each widget to its own size, so widgets against an edge stay there on a 32:9 screen.

  tools/preset-import.py --sync [REPO_DIR]   fetch Blapples/wallpapers (or use a clone) and install every preset and
                                             every wallpaper in it
  tools/preset-import.py --list [--json]     the installed presets (--json: for Nexus > Wallpaper & style > Presets)
  tools/preset-import.py PRESET [--mode light|dark] [--wallpapers DIR] [--dry-run]
  tools/preset-import.py --next | --previous the installed preset after (before) the one applied last, in --list's
                                             order, round the end (Ctrl+Super+P / Ctrl+Super+Shift+P); a press while
                                             one is still being applied is dropped
  tools/preset-import.py --undo              put back the settings from before the last import
  tools/preset-import.py --workspace WS      the preset workspace WS was given, applied (the shell runs it on a switch
                                             to WS, with background.workspacePresets on): no backup, nothing said,
                                             and nothing done while another apply runs (exit 75: asked again)
  tools/preset-import.py --forget [WS]       WS's preset forgotten (all workspaces' without WS)
  tools/preset-import.py --save-layout       the desktop widgets' places and sizes, as moved with the mouse, into the
                                             preset applied last (the shell runs it after a drag, resize or turn)

With background.workspacePresets on (Nexus > Wallpaper & style > Presets), a preset applied (Nexus,
Ctrl+Super+P, here) is the workspace's it was picked on from then on: preset-workspaces.json, next to preset-current;
an undo puts the workspaces' presets back as they were before it.

PRESET is an installed preset's name or a folder holding <name>.json and meta.json. Its pictures are looked for in
its folder, in --wallpapers (default: two levels up, the root of a clone of Blapples/wallpapers), in the Blapples
wallpapers and in the other presets (presets share pictures).

The pictures aren't licensed for sharing: they're copied to this computer only (Pictures/Wallpapers/Blapples and
Pictures/Wallpapers/presets/<name>), never into the repo.
"""
import argparse
import datetime
import fcntl
import filecmp
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HOME = Path.home()
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config"))  # where the shell reads and writes its config
II_CONFIG = CONFIG / "illogical-impulse/config.json"
SHELL_CONFIG = CONFIG / "caelestia/shell.json"
LOCKWALL = CONFIG / "hypr/hyprlock/lockwall.conf"
FACE = HOME / ".face"
STATE = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "caelestia4/preset-backups"
CURRENT = STATE.parent / "preset-current"  # the name of the preset applied last (kept in each backup, for --undo)
WORKSPACES = STATE.parent / "preset-workspaces.json"  # {workspace name: preset}, with background.workspacePresets on
BUSY = 75  # --workspace while another apply runs: EX_TEMPFAIL, the shell asks again
PICTURES = Path(subprocess.run(["xdg-user-dir", "PICTURES"], capture_output=True, text=True).stdout.strip() or HOME / "Pictures")
LIBRARY = Path(os.environ.get("XDG_DATA_HOME", HOME / ".local/share")) / "caelestia4/presets"
BLAPPLES_REPO = "https://github.com/Blapples/wallpapers"
BLAPPLES_CLONE = Path(os.environ.get("XDG_CACHE_HOME", HOME / ".cache")) / "caelestia4/blapples-wallpapers"
BLAPPLES_PICS = PICTURES / "Wallpapers/Blapples"
SWITCHWALL = CONFIG / "quickshell/ii/scripts/colors/switchwall.sh"
IMAGE_TYPES = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".avif"}

# end4-pC widgets this shell has (modules/caelestia/background/pcwidgets)
WIDGETS = ["clock", "weather", "calendar", "media", "customImage", "userCard", "worldClock", "resources", "notes", "timers",
           "todo", "images", "imageCard", "sticker", "customText"]
# the size end4-pC presets are made on: their widget x / y are pixels on a 1920x1080 screen
PRESET_CANVAS = {"width": 1920, "height": 1080}
# what moving, resizing and turning a desktop widget with the mouse changes (--save-layout): where it is, which one is on
# top, its size (a step or pixels) and angle, and whether a strip of cards stands up
LAYOUT_FIELDS = ("x", "y", "z", "sizeMode", "size", "rotation", "vertical")
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


def put_face(src):
    # whole, in one rename, with a new mtime: the shell's avatars reload when ~/.face changes, and a file still being
    # written over (or one as old as the last avatar, every preset's pictures are) would show half or none of it
    tmp = FACE.with_name(FACE.name + ".tmp")
    shutil.copyfile(src, tmp)
    os.chmod(tmp, 0o644)
    os.replace(tmp, FACE)


def find_picture(name, dirs):
    for d in dirs:
        p = d / name
        if p.is_file():
            return p
    return None


def preset_json(pdir):
    jsons = [p for p in pdir.glob("*.json") if p.name != "meta.json"]
    return jsons[0] if len(jsons) == 1 else None


def sync(repo):
    if repo is None:
        repo = BLAPPLES_CLONE
        if (repo / ".git").is_dir():
            subprocess.run(["git", "-C", str(repo), "pull", "--ff-only", "-q"], check=True)
        else:
            repo.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(["git", "clone", "--depth", "1", "-q", BLAPPLES_REPO, str(repo)], check=True)
    repo = repo.resolve()

    # every wallpaper: the ones wallpapers.json lists, and any other picture at the top of the repo
    listed = [w["filename"] for w in load(repo / "wallpapers.json")] if (repo / "wallpapers.json").is_file() else []
    names = dict.fromkeys(listed + sorted(p.name for p in repo.iterdir() if p.suffix.lower() in IMAGE_TYPES))
    BLAPPLES_PICS.mkdir(parents=True, exist_ok=True)
    copied = missing = 0
    for n in names:
        src, dst = repo / n, BLAPPLES_PICS / n
        if not src.is_file():
            missing += 1
            print(f"  - listed but not in the repo: {n}")
        elif not dst.is_file() or dst.stat().st_size != src.stat().st_size:
            shutil.copy2(src, dst)
            copied += 1
    print(f"wallpapers: {len(names) - missing} in {BLAPPLES_PICS} ({copied} new or changed)")

    # every preset, whole (its json, meta.json, previews and pictures), into the library
    presets = [d for d in sorted((repo / "presets").iterdir()) if d.is_dir() and preset_json(d)]
    for d in presets:
        sync_preset(d, LIBRARY / d.name)
    print(f"presets: {len(presets)} in {LIBRARY}  (apply one: tools/preset-import.py NAME)")


def sync_preset(src_dir, dst_dir):
    """Copy one preset from the clone into the library without losing what was changed there by hand."""
    base = dst_dir / ".upstream"  # each file as the last sync left it, to tell an edit here from a change upstream
    base.mkdir(parents=True, exist_ok=True)
    for src in sorted(src_dir.iterdir()):
        if not src.is_file():
            continue
        dst, old = dst_dir / src.name, base / src.name
        # a file changed here since the last sync (or, before the first one, one that differs at all) is kept
        edited = dst.is_file() and not filecmp.cmp(dst, old if old.is_file() else src, shallow=False)
        upstream_changed = not old.is_file() or not filecmp.cmp(src, old, shallow=False)
        if not edited:
            shutil.copy2(src, dst)
        elif upstream_changed:  # said once, when there's an update it doesn't take
            print(f"  - kept your changes: {dst_dir.name}/{src.name} (Blapples' version: {old})")
        shutil.copy2(src, old)


def installed():
    """The library's presets, by name (the order of --list, Nexus and --next)"""
    dirs = sorted(LIBRARY.iterdir(), key=lambda d: d.name.lower()) if LIBRARY.is_dir() else []
    return [(d, js) for d in dirs if (js := preset_json(d))]


def step(by):
    """The name of the preset `by` places from the one applied last (from the first or last, when none is)"""
    names = [d.name for d, _ in installed()]
    if not names:
        sys.exit("no presets installed (tools/preset-import.py --sync)")
    current = CURRENT.read_text().strip() if CURRENT.is_file() else ""
    if current not in names:
        return names[0 if by > 0 else -1]
    return names[(names.index(current) + by) % len(names)]


def workspaces():
    try:
        mapping = load(WORKSPACES)
        return mapping if isinstance(mapping, dict) else {}
    except (OSError, ValueError):
        return {}


def focused_workspace():
    """The workspace a preset is picked on, with background.workspacePresets on (else None): read when the apply
    starts, not when it's done (the focus may have moved on by then)"""
    try:
        if not load(II_CONFIG).get("background", {}).get("workspacePresets"):
            return None
        out = subprocess.run(["hyprctl", "activeworkspace", "-j"], capture_output=True, text=True, timeout=5).stdout
        ws = json.loads(out).get("name")  # a special workspace is never the active one
        return str(ws) if ws else None
    except (OSError, ValueError, subprocess.TimeoutExpired):
        return None


def give_workspace(name, ws):
    """Workspace `ws`'s preset is `name` from now on. Under the lock"""
    if ws:
        mapping = workspaces()
        mapping[ws] = name
        save(WORKSPACES, mapping)


def forget(ws):
    mapping = workspaces()
    if ws is True:
        mapping = {}
    else:
        mapping.pop(ws, None)
    save(WORKSPACES, mapping)


def notify(text):
    # one notification, replaced by the next press's; none without libnotify
    if shutil.which("notify-send"):
        subprocess.run(["notify-send", "-a", "Presets", "-i", "palette",
                        "-h", "string:x-canonical-private-synchronous:preset", "Preset", text], check=False)


def list_presets(as_json):
    presets = []
    for d, js in installed():
        pw = load(js).get("background", {}).get("widgets", {})
        on = [k for k, v in pw.items() if isinstance(v, dict) and v.get("enable") and k != "visualizer"]
        presets.append({
            "name": d.name,
            "preview": str(d / "preview.png") if (d / "preview.png").is_file() else "",
            "previewLock": str(d / "preview-lock.png") if (d / "preview-lock.png").is_file() else "",
            "widgets": [k for k in on if k in WIDGETS],
            "missing": [k for k in on if k not in WIDGETS],
        })
    if as_json:
        current = CURRENT.read_text().strip() if CURRENT.is_file() else ""
        undo = STATE.is_dir() and any(STATE.iterdir())
        print(json.dumps({"presets": presets, "current": current, "canUndo": undo, "library": str(LIBRARY),
                          "workspaces": workspaces()}, ensure_ascii=False))
        return
    for p in presets:
        print(f"{p['name']:24} " + ", ".join(p["widgets"] + [k + "*" for k in p["missing"]]))
    print("(* = a widget this shell doesn't have yet)")


def tidy(field, value):
    """Whole pixels on the canvas (a grid step on this screen is a fraction of one there), angles to a tenth: a preset
    file that reads like one made by hand. On a wider screen than the canvas a widget can land up to ~1.5 px off"""
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return value
    return round(value, 1) if field == "rotation" else round(value)


def save_layout():
    """The widgets' layout from the config back into the preset applied last, in the library (the copy --sync keeps)"""
    name = CURRENT.read_text().strip() if CURRENT.is_file() else ""
    js = preset_json(LIBRARY / name) if name else None
    if not js:
        return  # no preset applied, or it's gone from the library
    widgets = load(II_CONFIG).get("background", {}).get("widgets", {})
    if widgets.get("canvas") != PRESET_CANVAS:
        return  # the widgets were placed on another canvas since: their numbers don't mean the same in the preset
    preset = load(js)
    pwidgets = preset.get("background", {}).get("widgets", {})
    changed = []
    for key in WIDGETS:
        entry, pentry = widgets.get(key), pwidgets.get(key)
        if not isinstance(entry, dict) or not isinstance(pentry, dict) or not entry.get("enable"):
            continue  # a widget that's off wasn't moved, and the preset keeps it as it came
        for field in LAYOUT_FIELDS:
            if field in entry and pentry.get(field) != (value := tidy(field, entry[field])):
                pentry[field] = value
                changed.append(f"{key}.{field}")
    if changed:
        save(js, preset)
        print(f"{name}: saved {', '.join(changed)}")


def backup():
    # to the microsecond: two presets in a second (Ctrl+Super+P) each keep theirs; still in order by name
    dest = STATE / datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    dest.mkdir(parents=True)
    for src in (II_CONFIG, SHELL_CONFIG, LOCKWALL, FACE, CURRENT):
        if src.is_file():
            shutil.copy2(src, dest / src.name)
    # always, empty or not: the workspaces' presets before this one is given to one (an undo takes that back too)
    save(dest / WORKSPACES.name, workspaces())
    return dest


def undo():
    backups = sorted(STATE.glob("*")) if STATE.is_dir() else []
    if not backups:
        sys.exit("no preset backup to restore")
    last = backups[-1]
    # a setting changed since isn't taken back with the preset: the switch below the Undo button stays as it is
    per_workspace = load(II_CONFIG).get("background", {}).get("workspacePresets", False)
    for dst in (II_CONFIG, SHELL_CONFIG, LOCKWALL, FACE, CURRENT):
        src = last / dst.name
        if dst == FACE and src.is_file():
            put_face(src)
        elif src.is_file():
            shutil.copy2(src, dst)
        elif dst == FACE:
            dst.unlink(missing_ok=True)  # there was none: not the preset's left on
        elif dst == LOCKWALL:
            dst.write_text(LOCKWALL_DEFAULT)
        elif dst == CURRENT:
            dst.unlink(missing_ok=True)
    ii = load(II_CONFIG)
    if ii.get("background", {}).get("workspacePresets", False) != per_workspace:
        ii.setdefault("background", {})["workspacePresets"] = per_workspace
        save(II_CONFIG, ii)
    if (last / WORKSPACES.name).is_file():  # a backup from before presets per workspace has none: left as it is
        shutil.copy2(last / WORKSPACES.name, WORKSPACES)
    palette = ii.get("appearance", {}).get("palette", {})
    set_wallpaper(ii.get("background", {}).get("wallpaperPath"), accent=palette.get("accentColor", ""))
    shutil.rmtree(last)
    print(f"restored the settings from {last.name}")


def set_wallpaper(path, mode=None, scheme=None, accent=""):
    # end-4's switchwall.sh, waited for (the shell follows the wallpaper it saves), so its colour runs don't overlap:
    # a new wallpaper always clears the accent colour, so a preset's accent goes on after it, with the wallpaper kept
    # (--noswitch). mode: light / dark, None keeps the current one; scheme: the colour style (scheme-rainbow, ...)
    if not (path and Path(path).is_file()):
        return
    if not os.access(SWITCHWALL, os.X_OK):
        subprocess.run(["qs", "-c", "ii", "ipc", "call", "wallpaper", "set", str(path)], check=False)
        return
    opts = (["--mode", mode] if mode else []) + (["--type", scheme] if scheme else [])
    runs = [["--image", str(path)]] + ([["--noswitch", "--color", accent]] if accent else [])
    for run in runs:
        # its upscale question (notify-send) waits in the background: on a pipe of ours it would keep a reader (Nexus,
        # `| tail`) waiting for the answer, so its errors go through a file
        with tempfile.TemporaryFile("w+") as err:
            r = subprocess.run([str(SWITCHWALL), *run, *opts], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                               stderr=err, check=False, timeout=120)
            err.seek(0)
            if r.returncode:
                print(f"switchwall.sh {' '.join(run)}: exit {r.returncode}\n{err.read()}", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("preset", nargs="?", type=Path)
    ap.add_argument("--wallpapers", type=Path)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--mode", choices=["light", "dark"], help="light or dark colours (default: the preset's meta.json \"mode\", else the current one)")
    ap.add_argument("--undo", action="store_true")
    ap.add_argument("--next", dest="step", action="store_const", const=1)
    ap.add_argument("--previous", dest="step", action="store_const", const=-1)
    ap.add_argument("--sync", nargs="?", const=True, metavar="REPO_DIR")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--save-layout", action="store_true")
    ap.add_argument("--workspace", metavar="WS")
    ap.add_argument("--forget", nargs="?", const=True, metavar="WS")
    args = ap.parse_args()
    if args.step and (args.preset or args.undo or args.sync or args.list or args.save_layout):
        ap.error("--next / --previous go alone (with --mode, --wallpapers, --dry-run at most)")
    if args.workspace and (args.preset or args.step or args.undo or args.sync or args.list or args.save_layout):
        ap.error("--workspace goes alone")

    if args.list:
        return list_presets(args.json)
    # one at a time: an apply, an undo and a layout save each read preset-current and write the config, and a key held
    # down or pressed again mid-apply (switchwall takes seconds) would step from the same preset-current and run two
    # colour passes over each other; a --next / --previous then is dropped, the others wait
    STATE.parent.mkdir(parents=True, exist_ok=True)
    lock = open(STATE.parent / "preset.lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | (fcntl.LOCK_NB if args.step or args.workspace else 0))
    except BlockingIOError:
        # a workspace switch mid-apply: the shell asks again once this one is done (the last switch wins)
        sys.exit(BUSY if args.workspace else 0)
    if args.forget:
        return forget(args.forget)
    if args.save_layout:
        return save_layout()
    if args.undo:
        return undo()
    if args.sync:
        return sync(None if args.sync is True else Path(args.sync))
    if args.step:
        args.preset = LIBRARY / step(args.step)
    picked_on = None if args.workspace else focused_workspace()
    if args.workspace:
        name = workspaces().get(args.workspace)
        current = CURRENT.read_text().strip() if CURRENT.is_file() else ""
        if not name or name == current:
            return  # none given, or on already
        args.preset = LIBRARY / name
    if not args.preset:
        ap.error("give a preset (or --next, --previous, --sync, --list, --undo)")

    pdir = args.preset if args.preset.is_dir() else LIBRARY / args.preset
    if not pdir.is_dir():
        sys.exit(f"no preset {args.preset} (installed ones: tools/preset-import.py --list)")
    pdir = pdir.resolve()
    meta = load(pdir / "meta.json") if (pdir / "meta.json").is_file() else {}
    js = preset_json(pdir)
    if not js:
        sys.exit(f"{pdir}: expected one preset .json next to meta.json")
    preset = load(js)
    name = pdir.name
    search = [pdir, (args.wallpapers or pdir.parent.parent).resolve(), BLAPPLES_PICS]
    search += [d for d in sorted(pdir.parent.iterdir()) if d.is_dir() and d != pdir]

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
        if src.parent == BLAPPLES_PICS:
            return src  # already on this computer
        dst = out / src.name
        same = dst.is_file() and dst.stat().st_size == src.stat().st_size and dst.stat().st_mtime == src.stat().st_mtime
        if not args.dry_run and not same:  # copied already: a workspace switch doesn't copy them all again
            out.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
        return dst

    for w in meta.get("wallpapers", []):
        picture(w)
    wallpaper = picture(pbg.get("wallpaperPath"))
    lockwall = picture(pbg.get("lockWall"))
    avatar = picture(meta.get("avatar") or preset.get("profile", {}).get("avatarPicture"))
    banner = picture(meta.get("banner") or preset.get("sidebar", {}).get("bannerImage"))

    ii = load(II_CONFIG)
    widgets = ii.setdefault("background", {}).setdefault("widgets", {})
    widgets["canvas"] = dict(PRESET_CANVAS)
    for key in WIDGETS:
        if key not in pwidgets:
            widgets.setdefault(key, {})["enable"] = False
            continue
        entry = json.loads(json.dumps(pwidgets[key]))
        if key in ("customImage", "imageCard", "sticker"):
            img = picture(meta.get(key) or entry.get("path"))
            entry["path"] = str(img) if img else ""
        widgets[key] = entry
        applied.append(f"widget {key}" + ("" if entry.get("enable") else " (off)"))
    for key in sorted(set(pwidgets) - set(WIDGETS) - {"visualizer"}):
        if isinstance(pwidgets[key], dict) and pwidgets[key].get("enable"):
            skipped.append(f"widget {key} (not ported)")

    # the user card shows these
    ii["background"]["lockWall"] = str(lockwall) if lockwall else ""
    ii.setdefault("sidebar", {})["bannerImage"] = str(banner) if banner else ""
    if banner:
        applied.append(f"banner {banner.name}")

    # the colours: the style, the accent colour they're made from (none: from the wallpaper) and light / dark. end4-pC
    # keeps light / dark out of presets, so meta.json "mode" (or --mode) says which one the preview was taken in
    palette = preset.get("appearance", {}).get("palette", {})
    scheme = palette["type"] if palette.get("type") and palette["type"] != "auto" else None
    accent = palette.get("accentColor") or ""
    mode = args.mode or meta.get("mode")
    iipalette = ii.setdefault("appearance", {}).setdefault("palette", {})
    if scheme:
        iipalette["type"] = scheme
        applied.append(f"scheme {scheme}")
    iipalette["accentColor"] = accent
    applied.append(f"accent colour {accent}" if accent else "colours from the wallpaper")
    if mode:
        applied.append(f"{mode} mode")

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
    if args.step:  # said before the colour pass, the slow part
        notify(name)

    if not args.workspace:  # a switch isn't something to undo: Undo stays for the presets picked
        print(f"backup: {backup()}  (undo: tools/preset-import.py --undo)")
    save(II_CONFIG, ii)
    save(SHELL_CONFIG, shell)
    # always: a preset without one goes back to the desktop wallpaper, not the last preset's
    LOCKWALL.write_text(LOCKWALL_DEFAULT + (f"$background_image = {lockwall}\n" if lockwall else ""))
    if avatar:
        put_face(avatar)
    CURRENT.write_text(name + "\n")
    give_workspace(name, picked_on)
    set_wallpaper(wallpaper, mode, scheme, accent)


if __name__ == "__main__":
    main()

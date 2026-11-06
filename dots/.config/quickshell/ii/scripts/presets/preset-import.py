#!/usr/bin/env python3
"""caelestia4: apply an end4-pC preset (github.com/pctrade/end4-pC presets, e.g. Blapples/wallpapers/presets/<name>).

A preset is end4-pC's whole config.json plus its pictures. Only what this shell can show is taken (a whitelist, so a
preset can't set commands like apps.*): the desktop widgets end4-pC and this shell share (pcwidgets: clock, weather,
calendar, media, custom image, user card, world clock, resources, notes, timers, to-do, image converter, visualizer) at the preset's positions, the colours
(style, accent colour, light / dark), the wallpaper, the lock screen wallpaper, the banner (on the user card) and the avatar. The bar layout, AI, apps, Hyprland input and autostart are left alone.

Widget positions stay in the preset's 1920x1080 coordinates (background.widgets.canvas); each screen scales the room
around each widget to its own size, so widgets against an edge stay there on a 32:9 screen.

Presets come from two places, browsed and installed one at a time: Blapples/wallpapers (plain names) and the community's
pctrade/end4-pCpresets (installed as pctrade--<name>, as end4-pC does).

  tools/preset-import.py --catalog [--refresh] [--json]
                                             every preset of both sources, installed or not (from a list kept 6 h in
                                             ~/.cache/caelestia4/preset-catalog.json; --refresh: fetched again now;
                                             offline: the list kept, with "error" said)
  tools/preset-import.py --thumbs [NAME...]  the catalog's preview pictures, small, into ~/.cache/caelestia4/preset-thumbs
                                             ("thumb NAME" said as each one is ready)
  tools/preset-import.py --install NAME      that preset into the library (with the Blapples wallpapers it uses); not applied
  tools/preset-import.py --update [NAME]     that installed preset (all of them without NAME) fetched again: files you
                                             changed are kept (--sync: the same, all of them)
  tools/preset-import.py --sync REPO_DIR     every preset and wallpaper of a clone of Blapples/wallpapers, installed
  tools/preset-import.py --uninstall NAME    that preset out of the library (its pictures are left)
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
  tools/preset-import.py --save-layout       the desktop widgets' places, sizes and which ones are on, as changed on the
                                             desktop, into the preset applied last (the shell runs it after a change)
  tools/preset-import.py --disable           presets off: your own desktop back (wallpaper, widgets, lock wallpaper,
                                             avatar, banner, colours, light / dark) and presets refused until --enable
  tools/preset-import.py --enable            presets on: your desktop as it is now kept as your own, and the preset that
                                             was on when they were turned off applied again

With background.workspacePresets on (Nexus > Wallpaper & style > Presets), a preset applied (Nexus,
Ctrl+Super+P, here) is the workspace's it was picked on from then on: preset-workspaces.json, next to preset-current;
an undo puts the workspaces' presets back as they were before it.

With background.presetsEnabled off (--disable), applying, --next / --previous, --workspace, --undo and --save-layout do
nothing ("presets are off"). Your own desktop is ~/.local/state/caelestia4/preset-own.json (only what presets change),
taken by --enable; the first --disable takes it from the oldest preset backup (the desktop before presets were used).

PRESET is an installed preset's name or a folder holding <name>.json and meta.json. Its pictures are looked for in
its folder, in --wallpapers (default: two levels up, the root of a clone of Blapples/wallpapers), in the Blapples
wallpapers and in the other presets (presets share pictures).

The pictures aren't licensed for sharing: they're copied to this computer only (Pictures/Wallpapers/Blapples and
Pictures/Wallpapers/presets/<name>), never into the repo.

GitHub allows 60 listings an hour without a token: GITHUB_TOKEN / GH_TOKEN, else `gh auth token`, is used when there is
one (never printed). For tests only: PRESET_IMPORT_PICTURES and PRESET_IMPORT_FACE stand for Pictures and ~/.face.
"""
import argparse
import contextlib
import copy
import datetime
import fcntl
import filecmp
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

HOME = Path.home()
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config"))  # where the shell reads and writes its config
II_CONFIG = CONFIG / "illogical-impulse/config.json"
SHELL_CONFIG = CONFIG / "caelestia/shell.json"
LOCKWALL = CONFIG / "hypr/hyprlock/lockwall.conf"
FACE = Path(os.environ.get("PRESET_IMPORT_FACE") or HOME / ".face")  # PRESET_IMPORT_FACE: tests only
STATE_HOME = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state"))
STATE = STATE_HOME / "caelestia4/preset-backups"
CURRENT = STATE.parent / "preset-current"  # the name of the preset applied last (kept in each backup, for --undo)
WORKSPACES = STATE.parent / "preset-workspaces.json"  # {workspace name: preset}, with background.workspacePresets on
LAST = STATE.parent / "preset-last"  # the preset that was on when presets were turned off (--enable applies it again)
OWN = STATE.parent / "preset-own.json"  # your own desktop, for presets off: only what presets change
OWN_FACE = STATE.parent / "preset-own.face"  # and your own avatar (none: there was no ~/.face)
CAELESTIA_SCHEME = STATE_HOME / "caelestia/scheme.json"  # caelestia-cli's scheme: its "mode" is light / dark now
BUSY = 75  # --workspace while another apply runs: EX_TEMPFAIL, the shell asks again
PICTURES = Path(os.environ.get("PRESET_IMPORT_PICTURES")  # PRESET_IMPORT_PICTURES: tests only
                or subprocess.run(["xdg-user-dir", "PICTURES"], capture_output=True, text=True).stdout.strip()
                or HOME / "Pictures")
LIBRARY = Path(os.environ.get("XDG_DATA_HOME", HOME / ".local/share")) / "caelestia4/presets"
CACHE = Path(os.environ.get("XDG_CACHE_HOME", HOME / ".cache")) / "caelestia4"
CATALOG = CACHE / "preset-catalog.json"  # both sources' presets, as GitHub listed them last
CATALOG_AGE = 6 * 3600  # listed again after this (or with --refresh)
CATALOG_RETRY = 600  # a source that couldn't be listed isn't asked again before this (unless --refresh)
WIDGET_INFO = CACHE / "preset-widgets.json"  # the widgets of presets not installed, from their json (--thumbs)
THUMBS = CACHE / "preset-thumbs"
STAGING = CACHE / "preset-staging"  # a preset being downloaded, before it goes into the library
THUMB_WIDTH = 480
BLAPPLES_PICS = PICTURES / "Wallpapers/Blapples"
SWITCHWALL = CONFIG / "quickshell/ii/scripts/colors/switchwall.sh"
IMAGE_TYPES = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".avif"}
COMMUNITY = "pctrade--"  # the community's presets in the library (end4-pC names them so too)
# where presets come from (end4-pC's PresetsOnline): Blapples' use pictures at the top of the repo by name, the
# community's are whole in their folders; their authors are in a branch of their own
SOURCES = [
    {"id": "blapples", "repo": "Blapples/wallpapers", "branch": "main", "prefix": "", "rootWallpapers": True,
     "author": "Blapples"},
    {"id": "community", "repo": "pctrade/end4-pCpresets", "branch": "main", "prefix": COMMUNITY,
     "authors": "gallery-data"},
]

# end4-pC widgets this shell has (modules/caelestia/background/pcwidgets)
WIDGETS = ["clock", "weather", "calendar", "media", "customImage", "userCard", "worldClock", "resources", "notes", "timers",
           "todo", "images", "imageCard", "sticker", "customText", "visualizer"]
# end4-pC's visualizer defaults: most presets keep only enable and a place, and a style left from the preset before
# (an aurora, a ring) mustn't stay on
VISUALIZER_DEFAULTS = {"z": -1000, "style": "bars", "colorSource": "theme", "sensitivity": 1, "height": 260, "ringSize": 380}
# the size end4-pC presets are made on: their widget x / y are pixels on a 1920x1080 screen
PRESET_CANVAS = {"width": 1920, "height": 1080}
# what moving, resizing and turning a desktop widget with the mouse changes (--save-layout): where it is, which one is on
# top, its size (a step or pixels) and angle, and whether a strip of cards stands up
LAYOUT_FIELDS = ("x", "y", "z", "sizeMode", "size", "rotation", "vertical", "ringSize")
LOCKWALL_DEFAULT = "# caelestia4: a lock screen wallpaper of its own. Empty = the desktop wallpaper (colors.conf, from matugen).\n"
# what a preset changes, so what presets off puts back (preset-own.json): in the shell's config, in Caelestia's, and
# besides them the lock wallpaper (lockwall.conf), ~/.face and light / dark
OWN_II = (("background", "widgets"), ("background", "wallpaperPath"), ("background", "lockWall"),
          ("sidebar", "bannerImage"), ("appearance", "palette", "type"), ("appearance", "palette", "accentColor"))
OWN_SHELL = (("background", "visualiser", "enabled"), ("background", "desktopClock", "enabled"))
MISSING = object()
# a field your own desktop didn't have: the shell's default written out, never the key taken away (the running shell's
# JsonAdapter keeps the value it had for a key that's gone from the file, and writes it back)
OWN_DEFAULTS = {"background.lockWall": "", "sidebar.bannerImage": "", "appearance.palette.type": "auto",
                "appearance.palette.accentColor": "", "background.visualiser.enabled": False,
                "background.desktopClock.enabled": False}


class NetError(Exception):
    """GitHub couldn't be reached, or said no: one line, for the person and for Nexus"""


class Progress:
    """stdout, line by line: a reader that's gone (`| head`, Nexus closed) doesn't stop an apply half-way"""
    def __init__(self, out):
        self.out = out

    def _gone(self):
        os.dup2(os.open(os.devnull, os.O_WRONLY), self.out.fileno())

    def write(self, s):
        try:
            return self.out.write(s)
        except BrokenPipeError:
            self._gone()
            return self.out.write(s)

    def flush(self):
        try:
            self.out.flush()
        except BrokenPipeError:
            self._gone()
            self.out.flush()

    def __getattr__(self, name):
        return getattr(self.out, name)


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


@contextlib.contextmanager
def held(lock_name, wait=True):
    """A lock in the state folder, held for the with: True, or False when wait is off and it's taken"""
    STATE.parent.mkdir(parents=True, exist_ok=True)
    with open(STATE.parent / lock_name, "w") as f:
        try:
            fcntl.flock(f, fcntl.LOCK_EX | (0 if wait else fcntl.LOCK_NB))
        except BlockingIOError:
            yield False
            return
        yield True


def save(path, data):
    # a tmp of this process's own: --thumbs and --catalog (no lock) may write the same cache file as an install
    tmp = path.with_name(f".{path.name}.{os.getpid()}.tmp")
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


def safe_name(name):
    """A preset folder or file name from GitHub that stays where it's put: one name, not a path, not hidden"""
    return (isinstance(name, str) and bool(name) and not name.startswith(".") and "/" not in name and "\\" not in name
            and all(ord(c) >= 32 and c != "\x7f" for c in name))


def source_of(name):
    return "community" if name.startswith(COMMUNITY) else "blapples"


def title_of(name):
    """end4-pC's titles: the folder's name with spaces and capitals (pctrade--hu_tao: Hu Tao)"""
    folder = name[len(COMMUNITY):] if name.startswith(COMMUNITY) else name
    return re.sub(r"\b\w", lambda m: m.group().upper(), re.sub(r"[-_]+", " ", folder)).strip()


def presets_on(ii=None):
    try:
        ii = load(II_CONFIG) if ii is None else ii
    except (OSError, ValueError):
        return True
    return ii.get("background", {}).get("presetsEnabled", True) is not False


# --- GitHub ------------------------------------------------------------------------------------------------------------

_token = None


def github_token():
    """GITHUB_TOKEN / GH_TOKEN, else gh's (60 listings an hour become 5000); never printed"""
    global _token
    if _token is None:
        _token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN") or ""
        if not _token and shutil.which("gh"):
            try:
                _token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True, timeout=10,
                                        stdin=subprocess.DEVNULL).stdout.strip()
            except (OSError, subprocess.TimeoutExpired):
                _token = ""
    return _token


def http(url, api=False, timeout=30):
    """The response (open: read it, then close it). api: GitHub's API, with the token when there is one"""
    global _token
    headers = {"User-Agent": "caelestia4-presets"}
    if api:
        headers["Accept"] = "application/vnd.github+json"
        if github_token():
            headers["Authorization"] = f"Bearer {github_token()}"
    try:
        return urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=timeout)
    except urllib.error.HTTPError as e:
        if api and e.code == 401 and "Authorization" in headers:  # a token that's expired: without one then
            _token = ""
            return http(url, api, timeout)
        if e.code in (403, 429) and e.headers.get("X-RateLimit-Remaining") == "0":
            reset = e.headers.get("X-RateLimit-Reset", "")
            when = datetime.datetime.fromtimestamp(int(reset)).strftime("%H:%M") if reset.isdigit() else "an hour"
            raise NetError(f"GitHub's limit of listings is reached, try again after {when} "
                           "(or sign in with gh auth login)") from None
        raise NetError(f"GitHub said {e.code} {e.reason} for {urllib.parse.unquote(url.split('/', 3)[-1])}") from None
    except (urllib.error.URLError, OSError, ValueError) as e:
        reason = getattr(e, "reason", e)
        raise NetError(f"can't reach {urllib.parse.urlsplit(url).hostname} ({reason})") from None


def fetch(url, api=False):
    try:
        with http(url, api) as r:
            return r.read()
    except OSError as e:  # cut off mid-way
        raise NetError(f"can't reach {urllib.parse.urlsplit(url).hostname} ({e})") from None


def download(url, dest):
    """url into dest, whole or not at all"""
    part = dest.with_name(f".{dest.name}.part")
    try:
        with http(url, timeout=60) as r, open(part, "wb") as f:
            shutil.copyfileobj(r, f, 1 << 20)
    except OSError as e:
        part.unlink(missing_ok=True)
        raise NetError(f"can't download {dest.name} ({e})") from None
    except NetError:
        part.unlink(missing_ok=True)
        raise
    os.replace(part, dest)


def raw_url(src, path):
    return f"https://raw.githubusercontent.com/{src['repo']}/{src['branch']}/{urllib.parse.quote(path)}"


def git_sha(path):
    """The id GitHub's tree gives a file: a file here with the same one needn't be downloaded again"""
    h = hashlib.sha1(b"blob %d\0" % path.stat().st_size)
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def preview_of(images):
    """end4-pC's pick (PresetsOnline): preview.png, else a picture of the desktop, else one that isn't an avatar"""
    exact = [i for i in images if i.lower() == "preview.png"]
    others = [i for i in images if not re.fullmatch(r"previews?\.png", i, re.I)] or images
    return (exact or [i for i in others if re.search("desktop", i, re.I)]
            or [i for i in others if not re.search("pfp|avatar|banner", i, re.I)] or others)[0]


def list_source(src):
    """One source's presets, from GitHub's tree of its repo (one API call): {folder files, json, preview}"""
    url = f"https://api.github.com/repos/{src['repo']}/git/trees/{urllib.parse.quote(src['branch'])}?recursive=1"
    try:
        tree = json.loads(fetch(url, api=True))
    except ValueError:
        raise NetError(f"{src['repo']}: GitHub's answer isn't a list") from None
    if not isinstance(tree.get("tree"), list):
        raise NetError(f"{src['repo']}: GitHub's answer isn't a list")
    groups, root = {}, {}
    for e in tree["tree"]:
        parts = e.get("path", "").split("/") if e.get("type") == "blob" else []
        info = {"size": e.get("size", 0), "sha": e.get("sha", "")}
        if len(parts) == 1 and src.get("rootWallpapers") and safe_name(parts[0]) \
                and Path(parts[0]).suffix.lower() in IMAGE_TYPES:
            root[parts[0]] = info
        elif len(parts) == 3 and parts[0] == "presets" and safe_name(parts[1]) and safe_name(parts[2]):
            groups.setdefault(parts[1], {})[parts[2]] = info  # deeper files aren't the preset's: left out
    presets = {}
    for folder, files in groups.items():
        jsons = [f for f in files if f.lower().endswith(".json") and f != "meta.json"]
        images = sorted(f for f in files if Path(f).suffix.lower() in IMAGE_TYPES)
        if len(jsons) == 1 and images and safe_name(src["prefix"] + folder):
            presets[src["prefix"] + folder] = {"folder": folder, "files": files, "json": jsons[0],
                                               "preview": preview_of(images)}
    authors = {}
    if src.get("authors"):  # not there: no authors, the list is still good
        try:
            index = json.loads(fetch(raw_url({**src, "branch": src["authors"]}, "index.json")))
            authors = {src["prefix"] + k: v.get("author", "") for k, v in index.get("presets", {}).items()
                       if isinstance(v, dict)}
        except (NetError, ValueError, AttributeError):
            pass
    return {"fetched": int(time.time()), "presets": presets, "root": root, "authors": authors,
            "truncated": bool(tree.get("truncated"))}


def catalog(refresh=False, by_source=False):
    """(both sources' lists, an error or ""): a source listed less than 6 h ago isn't asked again; one that can't be
    reached keeps its last list, and isn't asked again for 10 min. by_source: the errors as {source id: error}"""
    try:
        cache = load(CATALOG)
        if not isinstance(cache.get("sources"), dict):
            raise ValueError
    except (OSError, ValueError, AttributeError):
        cache = {"version": 1, "sources": {}}
    errors, changed = {}, False
    for src in SOURCES:
        have = cache["sources"].get(src["id"])
        if not refresh and have and time.time() - have.get("fetched", 0) < CATALOG_AGE:
            continue
        failed = (have or {}).get("failed", {})
        if not refresh and time.time() - failed.get("at", 0) < CATALOG_RETRY:
            errors[src["id"]] = failed.get("error", "")  # a network that drops packets: not 30 s for each listing
            continue
        try:
            cache["sources"][src["id"]] = list_source(src)
        except NetError as e:
            errors[src["id"]] = str(e) if src["repo"] in str(e) else f"{src['repo']}: {e}"
            cache["sources"].setdefault(src["id"], {})["failed"] = {"at": int(time.time()), "error": errors[src["id"]]}
        changed = True
    if changed:
        CACHE.mkdir(parents=True, exist_ok=True)
        save(CATALOG, cache)
    return cache, errors if by_source else "; ".join(dict.fromkeys(e for e in errors.values() if e))


def find_entry(cache, name):
    """(source, its list, the preset's entry) for a preset in the catalog, else None"""
    for src in SOURCES:
        listed = cache["sources"].get(src["id"])
        if listed and name in listed.get("presets", {}):
            return src, listed, listed["presets"][name]
    return None


def thumb_of(name):
    for ext in [".jpg", *sorted(IMAGE_TYPES - {".jpg"})]:
        if (THUMBS / (name + ext)).is_file():
            return THUMBS / (name + ext)
    return None


def widgets_of(preset):
    """(the widgets a preset has on that this shell has, those it hasn't)"""
    pw = preset.get("background", {}).get("widgets", {}) if isinstance(preset, dict) else {}
    on = [k for k, v in pw.items() if isinstance(v, dict) and v.get("enable")] if isinstance(pw, dict) else []
    return [k for k in on if k in WIDGETS], [k for k in on if k not in WIDGETS]


def widget_info():
    try:
        info = load(WIDGET_INFO)
        return info if isinstance(info, dict) else {}
    except (OSError, ValueError):
        return {}


def catalog_entries(cache):
    """Every preset, as --catalog lists them: the sources' and any installed one they don't list (yours, or gone)"""
    info, entries = widget_info(), {}
    for src in SOURCES:
        listed = cache["sources"].get(src["id"]) or {}
        for name, p in listed.get("presets", {}).items():
            entries[name] = {"name": name, "title": title_of(name), "source": src["id"],
                             "author": src.get("author") or listed.get("authors", {}).get(name, ""),
                             "_json_sha": p["files"][p["json"]]["sha"]}
    for d, _ in installed():
        entries.setdefault(d.name, {"name": d.name, "title": title_of(d.name), "source": source_of(d.name), "author": ""})
    out = []
    for name, e in entries.items():
        d = LIBRARY / name
        js = preset_json(d) if d.is_dir() else None
        e["installed"] = bool(js)
        widgets, missing = [], []
        if js:
            try:
                widgets, missing = widgets_of(load(js))
            except (OSError, ValueError):
                pass
        elif info.get(name, {}).get("sha") == e.get("_json_sha"):
            widgets, missing = info[name].get("widgets", []), info[name].get("missing", [])
        thumb = thumb_of(name) or (d / "preview.png" if js and (d / "preview.png").is_file() else None)
        e.pop("_json_sha", None)
        out.append({**e, "preview": str(thumb) if thumb else "", "widgets": widgets, "missing": missing})
    return sorted(out, key=lambda e: (e["title"].lower(), e["source"], e["name"]))


def show_catalog(refresh, as_json):
    cache, error = catalog(refresh)
    entries = catalog_entries(cache)
    fetched = [s["fetched"] for s in cache["sources"].values() if "fetched" in s]
    if as_json:
        print(json.dumps({"presets": entries, "fetched": min(fetched) if fetched else 0, "error": error},
                         ensure_ascii=False))
        return
    for e in entries:
        print(f"{'*' if e['installed'] else ' '} {e['name']:32} {e['source']:9} {e['author']}")
    print("(* = installed)")
    if error:
        print(f"error: {error}", file=sys.stderr)


def make_thumb(name, src, entry):
    """The preset's preview, 480 px wide, into the thumbs (from the library when it's installed)"""
    THUMBS.mkdir(parents=True, exist_ok=True)
    fname = entry["preview"]
    local = LIBRARY / name / fname
    tmp = None
    if not local.is_file():
        tmp = THUMBS / f".{name}.{os.getpid()}.src{Path(fname).suffix.lower()}"
        download(raw_url(src, f"presets/{entry['folder']}/{fname}"), tmp)
        local = tmp
    out, part = THUMBS / f"{name}.jpg", THUMBS / f".{name}.{os.getpid()}.part.jpg"
    try:
        made = False
        if shutil.which("magick"):
            made = subprocess.run(["magick", f"{local}[0]", "-auto-orient", "-resize", f"{THUMB_WIDTH}x>",
                                   "-quality", "82", f"jpg:{part}"], capture_output=True, timeout=120).returncode == 0
        elif shutil.which("ffmpeg"):
            made = subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(local), "-frames:v", "1",
                                   "-vf", f"scale='min({THUMB_WIDTH},iw)':-2", str(part)],
                                  capture_output=True, timeout=120, stdin=subprocess.DEVNULL).returncode == 0
        if made and part.is_file():
            os.replace(part, out)
        else:  # nothing to make it smaller with (or it couldn't): the picture as it is
            out = THUMBS / (name + Path(fname).suffix.lower())
            shutil.copyfile(local, out)
    finally:
        part.unlink(missing_ok=True)
        if tmp:
            tmp.unlink(missing_ok=True)
    for ext in IMAGE_TYPES:  # one thumb a preset
        if (other := THUMBS / (name + ext)) != out:
            other.unlink(missing_ok=True)


def thumbs(names):
    """The thumbs (and widget lists) the catalog's presets don't have yet, each said as it's ready ("thumb NAME")"""
    cache, error = catalog()
    if not any(s.get("presets") for s in cache["sources"].values()):
        sys.exit(f"no catalog: {error or 'nothing listed'}")
    info, failed = widget_info(), 0
    wanted = names or [n for s in SOURCES for n in sorted((cache["sources"].get(s["id"]) or {}).get("presets", {}))]
    for name in wanted:
        found = find_entry(cache, name)
        if not found:
            print(f"  - not in the catalog: {name}", file=sys.stderr)
            failed += 1
            continue
        src, _, entry = found
        changed = False
        try:
            if not thumb_of(name):
                make_thumb(name, src, entry)
                changed = True
            sha = entry["files"][entry["json"]]["sha"]
            is_installed = (LIBRARY / name).is_dir() and preset_json(LIBRARY / name)
            if not is_installed and info.get(name, {}).get("sha") != sha:  # what it has on, for the list, before it's installed
                widgets, missing = widgets_of(json.loads(fetch(raw_url(src, f"presets/{entry['folder']}/{entry['json']}"))))
                info[name] = {"sha": sha, "widgets": widgets, "missing": missing}
                CACHE.mkdir(parents=True, exist_ok=True)
                save(WIDGET_INFO, info)
                changed = True
        except (NetError, OSError, ValueError, subprocess.TimeoutExpired) as e:
            print(f"  - {name}: {e}", file=sys.stderr)
            failed += 1
        if changed:
            print(f"thumb {name}", flush=True)
    if failed and failed == len(wanted):
        sys.exit(1)


# --- the library -------------------------------------------------------------------------------------------------------

def sync(repo):
    """Every wallpaper and preset of a clone of Blapples/wallpapers into this computer (no download)"""
    repo = repo.resolve()

    # every wallpaper: the ones wallpapers.json lists, and any other picture at the top of the repo
    listed = [w["filename"] for w in load(repo / "wallpapers.json")] if (repo / "wallpapers.json").is_file() else []
    names = dict.fromkeys(listed + sorted(p.name for p in repo.iterdir() if p.suffix.lower() in IMAGE_TYPES))
    BLAPPLES_PICS.mkdir(parents=True, exist_ok=True)
    copied = missing = 0
    for n in names:
        src, dst = repo / n, BLAPPLES_PICS / n
        if not safe_name(n) or not src.is_file():
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
            print(f"  - kept your changes: {dst_dir.name}/{src.name} (the upstream version: {old})")
        shutil.copy2(src, old)


def referenced_pictures(*docs):
    """The picture names a preset's json and meta.json name anywhere (paths or names)"""
    names = set()
    def walk(v):
        if isinstance(v, dict):
            for x in v.values():
                walk(x)
        elif isinstance(v, list):
            for x in v:
                walk(x)
        elif isinstance(v, str) and Path(v).suffix.lower() in IMAGE_TYPES:
            names.add(v.rsplit("/", 1)[-1])
    for d in docs:
        walk(d)
    return names


def install(name, cache):
    """One preset from the catalog into the library: its folder (a file already here as GitHub has it isn't
    downloaded again; one changed here is kept, as --sync did) and, for Blapples', the wallpapers it names from the
    top of the repo. Not applied"""
    found = find_entry(cache, name)
    if not found:
        raise NetError(f"no preset {name} in the catalog")
    src, listed, entry = found
    dst, staging = LIBRARY / name, STAGING / name
    shutil.rmtree(staging, ignore_errors=True)
    staging.mkdir(parents=True)
    try:
        files = sorted(entry["files"].items())
        got = 0
        for i, (fname, info) in enumerate(files, 1):
            here = [p for p in (dst / ".upstream" / fname, dst / fname) if p.is_file()]
            same = next((p for p in here if p.stat().st_size == info["size"] and git_sha(p) == info["sha"]), None)
            if same:
                shutil.copy2(same, staging / fname)
                continue
            print(f"  {i}/{len(files)} {fname}", flush=True)
            download(raw_url(src, f"presets/{entry['folder']}/{fname}"), staging / fname)
            got += 1
        walls = 0
        if src.get("rootWallpapers"):
            docs = []
            for fname in (entry["json"], "meta.json"):
                try:
                    docs.append(load(staging / fname))
                except (OSError, ValueError):
                    pass
            wanted = sorted(n for n in referenced_pictures(*docs) if n in listed.get("root", {}) and n not in entry["files"])
            for n in wanted:
                out = BLAPPLES_PICS / n
                if out.is_file() and out.stat().st_size == listed["root"][n]["size"]:
                    continue
                print(f"  wallpaper {n}", flush=True)
                BLAPPLES_PICS.mkdir(parents=True, exist_ok=True)
                download(raw_url(src, n), out)
                walls += 1
        LIBRARY.mkdir(parents=True, exist_ok=True)
        with held("preset.lock"):  # only the copy into the library waits for an apply, not the download
            sync_preset(staging, dst)
    finally:
        shutil.rmtree(staging, ignore_errors=True)
        try:
            STAGING.rmdir()  # when no other preset is being downloaded
        except OSError:
            pass
    walls = f", {walls} wallpaper{'s' if walls > 1 else ''}" if walls else ""
    print(f"{name}: {got} of {len(files)} files downloaded{walls} ({dst})")


def update(name):
    """One installed preset (all of them: None) fetched again, from a catalog listed now"""
    cache, errors = catalog(refresh=True, by_source=True)
    if name and not (safe_name(name) and (LIBRARY / name).is_dir() and preset_json(LIBRARY / name)):
        sys.exit(f"no preset {name} installed")
    names = [name] if name else [d.name for d, _ in installed()]
    failed = []
    for n in names:
        if source_of(n) in errors:  # the list kept from before would say nothing changed
            print(f"  - {n}: can't update ({errors[source_of(n)]})", file=sys.stderr)
            failed.append(n)
            continue
        if not find_entry(cache, n):
            print(f"  - {n}: not in the catalog, kept as it is")
            continue
        try:
            install(n, cache)
        except NetError as e:
            print(f"  - {n}: {e}", file=sys.stderr)
            failed.append(n)
    if failed:
        sys.exit(f"not updated: {', '.join(failed)}")


def uninstall(name):
    if not safe_name(name) or not (LIBRARY / name).is_dir():
        sys.exit(f"no preset {name} installed")
    shutil.rmtree(LIBRARY / name)
    mapping = workspaces()
    if any(v == name for v in mapping.values()):
        save(WORKSPACES, {k: v for k, v in mapping.items() if v != name})
    for f in (CURRENT, LAST):
        if f.is_file() and f.read_text().strip() == name:
            f.unlink()
    print(f"{name}: uninstalled (its pictures are still in {PICTURES / 'Wallpapers'})")


def installed():
    """The library's presets, by name (the order of --list, Nexus and --next)"""
    dirs = sorted((d for d in LIBRARY.iterdir() if d.is_dir() and not d.name.startswith(".")),
                  key=lambda d: d.name.lower()) if LIBRARY.is_dir() else []
    return [(d, js) for d in dirs if (js := preset_json(d))]


def step(by):
    """The name of the preset `by` places from the one applied last (from the first or last, when none is)"""
    names = [d.name for d, _ in installed()]
    if not names:
        sys.exit("no presets installed (tools/preset-import.py --install NAME)")
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
        try:
            widgets, missing = widgets_of(load(js))
        except (OSError, ValueError, AttributeError):  # edited by hand, or being copied by --update: listed all the same
            widgets, missing = [], []
        presets.append({
            "name": d.name,
            "title": title_of(d.name),
            "source": source_of(d.name),
            "preview": str(d / "preview.png") if (d / "preview.png").is_file() else "",
            "previewLock": str(d / "preview-lock.png") if (d / "preview-lock.png").is_file() else "",
            "widgets": widgets,
            "missing": missing,
        })
    if as_json:
        current = CURRENT.read_text().strip() if CURRENT.is_file() else ""
        undo = STATE.is_dir() and any(STATE.iterdir())
        print(json.dumps({"presets": presets, "current": current, "canUndo": undo, "library": str(LIBRARY),
                          "workspaces": workspaces(), "enabled": presets_on()}, ensure_ascii=False))
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
    """The widgets' layout from the config back into the preset applied last, in the library (the copy --update
    keeps): places and sizes, and which widgets are on (one turned off is off in the preset, one added comes whole)"""
    name = CURRENT.read_text().strip() if CURRENT.is_file() else ""
    js = preset_json(LIBRARY / name) if name else None
    if not js:
        return  # no preset applied, or it's gone from the library
    widgets = load(II_CONFIG).get("background", {}).get("widgets", {})
    if widgets.get("canvas") != PRESET_CANVAS:
        return  # the widgets were placed on another canvas since: their numbers don't mean the same in the preset
    preset = load(js)
    pwidgets = preset.setdefault("background", {}).setdefault("widgets", {})
    changed = []
    for key in WIDGETS:
        entry, pentry = widgets.get(key), pwidgets.get(key)
        if not isinstance(entry, dict):
            continue
        on, pon = bool(entry.get("enable")), isinstance(pentry, dict) and bool(pentry.get("enable"))
        if not on:
            if pon:  # taken off the desktop: off in the preset too, kept as it was for turning on again
                pentry["enable"] = False
                changed.append(f"{key} off")
            continue  # a widget that's off wasn't moved, and the preset keeps it as it came
        if not pon:  # put on the desktop: the config's whole widget, on the preset's canvas
            pwidgets[key] = {k: tidy(k, v) if k in LAYOUT_FIELDS else v for k, v in entry.items()}
            # a picture of yours goes into the preset's folder: apply finds pictures there by name, not by path
            pic = Path(entry.get("path") or "") if isinstance(entry.get("path"), str) else None
            if pic and pic.suffix.lower() in IMAGE_TYPES and pic.is_file() and pic.parent != js.parent \
                    and not (js.parent / pic.name).exists():
                shutil.copy2(pic, js.parent / pic.name)
            changed.append(f"{key} on")
            continue
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
    # a setting changed since isn't taken back with the preset: the switches below the Undo button stay as they are
    bg = load(II_CONFIG).get("background", {})
    kept = {k: bg[k] for k in ("workspacePresets", "presetsEnabled") if k in bg}
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
    bg = ii.setdefault("background", {})
    if any(bg.get(k, MISSING) != v for k, v in kept.items()):
        bg.update(kept)
        save(II_CONFIG, ii)
    if (last / WORKSPACES.name).is_file():  # a backup from before presets per workspace has none: left as it is
        shutil.copy2(last / WORKSPACES.name, WORKSPACES)
    palette = ii.get("appearance", {}).get("palette", {})
    set_wallpaper(ii.get("background", {}).get("wallpaperPath"), accent=palette.get("accentColor", ""))
    shutil.rmtree(last)
    print(f"restored the settings from {last.name}")


# --- presets on / off --------------------------------------------------------------------------------------------------

def dig(d, path):
    for k in path:
        if not isinstance(d, dict) or k not in d:
            return MISSING
        d = d[k]
    return d


def put(d, path, value):
    """value at path (MISSING: taken out, the shell's default then)"""
    for k in path[:-1]:
        if not isinstance(d.get(k), dict):
            if value is MISSING:
                return
            d[k] = {}
        d = d[k]
    if value is MISSING:
        d.pop(path[-1], None)
    else:
        d[path[-1]] = value


def current_mode():
    """light / dark now: caelestia-cli's scheme (switchwall.sh keeps it), else GNOME's preference"""
    try:
        mode = load(CAELESTIA_SCHEME).get("mode")
        if mode in ("light", "dark"):
            return mode
    except (OSError, ValueError, AttributeError):
        pass
    try:
        out = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"],
                             capture_output=True, text=True, timeout=5).stdout
        return "dark" if "dark" in out else "light" if "light" in out else ""
    except (OSError, subprocess.TimeoutExpired):
        return ""


def take_own(ii, shell, lockwall, face, mode, origin, widgets_off=False):
    """What presets change, as it is in these files, kept as your own desktop (preset-own.json + preset-own.face)"""
    own = {"origin": origin, "taken": datetime.datetime.now().isoformat(timespec="seconds"),
           "ii": {".".join(p): v for p in OWN_II if (v := dig(ii, p)) is not MISSING},
           "shell": {".".join(p): v for p in OWN_SHELL if (v := dig(shell, p)) is not MISSING},
           "lockwall": lockwall, "face": bool(face and face.is_file()), "mode": mode or ""}
    if widgets_off and isinstance(own["ii"].get("background.widgets"), dict):
        # the desktop as it is, but the preset's widgets aren't yours: all off, each kept where it was
        for key, entry in own["ii"]["background.widgets"].items():
            if isinstance(entry, dict) and "enable" in entry:  # not the canvas
                entry["enable"] = False
    STATE.parent.mkdir(parents=True, exist_ok=True)
    if own["face"]:
        shutil.copyfile(face, OWN_FACE)
    else:
        OWN_FACE.unlink(missing_ok=True)
    save(OWN, own)
    return own


def first_own():
    """Your own desktop the first time presets go off: the oldest preset backup's (from before presets were used),
    else the desktop now without the preset's widgets"""
    backups = [b for b in sorted(STATE.glob("*")) if (b / II_CONFIG.name).is_file()] if STATE.is_dir() else []
    if backups:
        b = backups[0]
        shell = load(b / SHELL_CONFIG.name) if (b / SHELL_CONFIG.name).is_file() else {}
        lockwall = (b / LOCKWALL.name).read_text() if (b / LOCKWALL.name).is_file() else None
        face = next((f for f in (b / FACE.name, b / ".face") if f.is_file()), None)
        # light / dark then wasn't kept: as it is now
        return take_own(load(b / II_CONFIG.name), shell, lockwall, face, "", f"backup {b.name}")
    shell = load(SHELL_CONFIG) if SHELL_CONFIG.is_file() else {}
    lockwall = LOCKWALL.read_text() if LOCKWALL.is_file() else None
    return take_own(load(II_CONFIG), shell, lockwall, FACE, current_mode(), "the desktop, widgets off", widgets_off=True)


def own_widgets(now, own):
    """Your own widgets over the ones on now: a widget yours doesn't have is turned off (kept where it is), and the
    canvas and scale are yours (none: the screen's own)"""
    out = copy.deepcopy(now) if isinstance(now, dict) else {}
    own = own if isinstance(own, dict) else {}
    for key, entry in out.items():
        if key not in own and isinstance(entry, dict) and "enable" in entry:
            entry["enable"] = False
    out.update(copy.deepcopy(own))
    if "canvas" not in own:
        out["canvas"] = {"width": 0, "height": 0}
    if "scale" not in own:
        out["scale"] = 0
    return out


def disable():
    """Presets off: your own desktop back, and presets refused until --enable (the one on is remembered for it)"""
    ii = load(II_CONFIG)
    if not presets_on(ii):
        print("presets are off already")
        return
    try:
        own = load(OWN)
        if not isinstance(own.get("ii"), dict):
            raise ValueError
    except (OSError, ValueError, AttributeError):
        own = first_own()
    for path in OWN_II:
        key = ".".join(path)
        if path == ("background", "widgets"):
            put(ii, path, own_widgets(dig(ii, path), own["ii"].get(key)))
        elif key == "background.wallpaperPath":
            wp = own["ii"].get(key)
            if wp and Path(wp).is_file():
                put(ii, path, wp)
            elif wp:
                print(f"your wallpaper {wp} is gone: the one on stays, pick one of yours", file=sys.stderr)
        elif key in own["ii"] or key in OWN_DEFAULTS:
            put(ii, path, own["ii"].get(key, OWN_DEFAULTS.get(key)))
        # wallpaperPath: none of yours, the one on stays (an empty one would leave the desktop bare)
    ii.setdefault("background", {})["presetsEnabled"] = False
    shell = load(SHELL_CONFIG) if SHELL_CONFIG.is_file() else {}
    for path in OWN_SHELL:
        key = ".".join(path)
        put(shell, path, own.get("shell", {}).get(key, OWN_DEFAULTS[key]))
    current = CURRENT.read_text().strip() if CURRENT.is_file() else ""
    if current:
        LAST.write_text(current + "\n")
    save(II_CONFIG, ii)
    if SHELL_CONFIG.is_file() or shell:
        save(SHELL_CONFIG, shell)
    LOCKWALL.parent.mkdir(parents=True, exist_ok=True)
    LOCKWALL.write_text(own.get("lockwall") or LOCKWALL_DEFAULT)
    if own.get("face") and OWN_FACE.is_file():
        put_face(OWN_FACE)
    else:
        FACE.unlink(missing_ok=True)  # there was none: not the preset's left on
    CURRENT.unlink(missing_ok=True)
    print(f"presets off: your own desktop back (from {own.get('origin', 'preset-own.json')})"
          + (f"; {current} goes back on with --enable" if current else ""))
    palette = ii.get("appearance", {}).get("palette", {})
    scheme = palette.get("type")
    set_wallpaper(ii.get("background", {}).get("wallpaperPath"), own.get("mode") or None,
                  None if scheme in (None, "", "auto") else scheme, palette.get("accentColor", ""))


def enable(args):
    """Presets on: the desktop as it is now kept as your own (picks made while presets were off), then the preset that
    was on applied again, with a backup as any apply"""
    ii = load(II_CONFIG)
    if presets_on(ii):
        print("presets are on already")
        return
    shell = load(SHELL_CONFIG) if SHELL_CONFIG.is_file() else {}
    take_own(ii, shell, LOCKWALL.read_text() if LOCKWALL.is_file() else None, FACE, current_mode(), "presets turned on")
    ii.setdefault("background", {})["presetsEnabled"] = True
    save(II_CONFIG, ii)
    def usable(n):
        return bool(n and safe_name(n) and (LIBRARY / n).is_dir() and preset_json(LIBRARY / n))
    last = LAST.read_text().strip() if LAST.is_file() else ""
    # the focused workspace's own preset when it has one (presets per workspace on), else the one that was on
    ws = focused_workspace()
    name = target if (target := workspaces().get(ws) if ws else None) and usable(target) else last
    if usable(name):
        print(f"presets on: {name} again")
        args.keep_workspaces = True  # no workspace given this one: each keeps its own
        apply(LIBRARY / name, args)
        LAST.unlink(missing_ok=True)
    else:
        print("presets on (no preset to put back: pick one)")


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


def apply(preset_arg, args):
    """A preset onto the desktop (args: mode, wallpapers, dry_run, step, workspace)"""
    # picked by hand: given to the workspace that's focused (with presets per workspace on); by a switch or --enable: not
    picked_on = None if args.workspace or getattr(args, "keep_workspaces", False) else focused_workspace()
    pdir = preset_arg if preset_arg.is_dir() else LIBRARY / preset_arg
    if not pdir.is_dir():
        sys.exit(f"no preset {preset_arg} (installed ones: tools/preset-import.py --list)")
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
        if not path_or_name or not isinstance(path_or_name, str):
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
        if key == "visualizer":
            entry = {**VISUALIZER_DEFAULTS, **entry}
        if key in ("customImage", "imageCard", "sticker"):
            img = picture(meta.get(key) or entry.get("path"))
            entry["path"] = str(img) if img else ""
        widgets[key] = entry
        applied.append(f"widget {key}" + ("" if entry.get("enable") else " (off)"))
    for key in sorted(set(pwidgets) - set(WIDGETS)):
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
    # "auto" (most presets) goes into the config too: switchwall.sh then picks the style from the wallpaper
    # (scheme_for_image.py) for an accent colour's scheme, as end-4 did for the preview; left as it was, the last
    # preset's style (a grey neutral, say) made it. It isn't passed as --type, which would also leave a named scheme
    # picked in Nexus (and Caelestia's smart scheme) for wallpaper colours
    scheme = palette.get("type") or "auto"
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
    # one visualiser: the preset's (the visualizer widget, on or off), not Caelestia's bars as well
    sbg.setdefault("visualiser", {})["enabled"] = False
    applied.append("Caelestia visualiser off")
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
    LOCKWALL.parent.mkdir(parents=True, exist_ok=True)
    LOCKWALL.write_text(LOCKWALL_DEFAULT + (f"$background_image = {lockwall}\n" if lockwall else ""))
    if avatar:
        put_face(avatar)
    CURRENT.write_text(name + "\n")
    give_workspace(name, picked_on)
    set_wallpaper(wallpaper, mode, None if scheme == "auto" else scheme, accent)


def main():
    sys.stdout.reconfigure(line_buffering=True)  # progress for Nexus as it comes, on a pipe too
    sys.stdout = Progress(sys.stdout)
    ap =argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
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
    ap.add_argument("--catalog", action="store_true")
    ap.add_argument("--refresh", action="store_true")
    ap.add_argument("--thumbs", nargs="*", metavar="NAME")
    ap.add_argument("--install", metavar="NAME")
    ap.add_argument("--update", nargs="?", const=True, metavar="NAME")
    ap.add_argument("--uninstall", metavar="NAME")
    ap.add_argument("--enable", action="store_true")
    ap.add_argument("--disable", action="store_true")
    args = ap.parse_args()
    commands = [c for c in ("preset", "step", "workspace", "undo", "sync", "list", "save_layout", "forget", "catalog",
                            "install", "update", "uninstall", "enable", "disable") if getattr(args, c)]
    commands += ["thumbs"] if args.thumbs is not None else []
    if len(commands) > 1:
        ap.error(f"one at a time: {', '.join('--' + c.replace('_', '-') for c in commands)}")

    try:
        # only reading GitHub and the library (and caches of their own): no lock, beside an apply
        if args.list:
            return list_presets(args.json)
        if args.catalog:
            return show_catalog(args.refresh, args.json)
        if args.thumbs is not None:
            return thumbs(args.thumbs)
    except NetError as e:
        sys.exit(str(e))

    # downloads one after another (two of the same preset would share its staging folder), beside applies and switches
    try:
        if args.install or args.update or args.sync is True:
            with held("preset-download.lock"):
                if args.install:
                    if not safe_name(args.install):
                        sys.exit(f"no preset {args.install} in the catalog")
                    cache, error = catalog()
                    if not find_entry(cache, args.install):  # new since the list was made, maybe
                        cache, error = catalog(refresh=True)
                    if not find_entry(cache, args.install):
                        sys.exit(f"no preset {args.install} in the catalog" + (f" ({error})" if error else ""))
                    return install(args.install, cache)
                return update(None if args.update in (None, True) else args.update)
    except NetError as e:
        sys.exit(str(e))

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
    try:
        if args.forget:
            return forget(args.forget)
        if args.sync:
            return sync(Path(args.sync))
        if args.uninstall:
            return uninstall(args.uninstall)
        if args.disable:
            return disable()
        if args.enable:
            return enable(args)
    except NetError as e:
        sys.exit(str(e))

    # presets off: none goes on (the keys, a workspace switch, Nexus), nor is a layout saved into one
    if (args.preset or args.step or args.workspace or args.undo or args.save_layout) and not presets_on():
        if not args.save_layout:
            print("presets are off (turn them on: Nexus > Wallpaper & style > Presets, or --enable)")
            if args.step:
                notify("Presets are off")
        return
    if args.save_layout:
        return save_layout()
    if args.undo:
        return undo()
    if args.step:
        args.preset = LIBRARY / step(args.step)
    if args.workspace:
        name = workspaces().get(args.workspace)
        current = CURRENT.read_text().strip() if CURRENT.is_file() else ""
        if not name or name == current:
            return  # none given, or on already
        args.preset = LIBRARY / name
    if not args.preset:
        ap.error("give a preset (or --next, --previous, --catalog, --install, --list, --undo, ...)")
    apply(args.preset, args)


if __name__ == "__main__":
    main()

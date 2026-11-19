#!/usr/bin/env python3
"""caelestia4: put the apps that keep a key on KWallet or on gnome-keyring, one app at a time or all of them, in
either direction. Each app's key goes with it, read back before the app is pointed at the new store, so what it
encrypted (sign-ins, cookies, saved passwords) stays readable.

  tools/keyring-switch.py status [APP...]             every app found, where its store is set, its key in each store
  tools/keyring-switch.py set gnome|kwallet APP...     move these apps (names as status shows them)
  tools/keyring-switch.py set gnome|kwallet --all      every app that keeps a key
      --dry-run   print the plan, change nothing
      --name LIB[,KW]  the app's key name (libsecret application=, KWallet "<KW> Keys"), when status can't tell
      --unset-only  only the apps no file sets a store for, on a desktop that gives them none (what installs use)

Apps are found from the desktop entries (yours first, then the system's), not from a list: Chromium-based browsers,
Electron apps, and python-keyring. The store goes where that app reads it: ~/<data folder>/argv.json (VS Code family),
the flags file its launcher reads (brave-flags.conf, obsidian/user-flags.conf...), or else a copy of its desktop entry
in ~/.local/share/applications. Your own entries that start the app without its launcher (autostart, web apps) get the
flag too. Shared files (electronNN-flags.conf) are left alone. A running app keeps its store until it fully quits.

gh, Zed, the shell's API keys and other libsecret apps can't choose: they use whoever serves org.freedesktop.secrets
(tools/keyring-switch.sh prepare/finish moves that to gnome-keyring). Values are never printed.
"""
import argparse
import json
import mmap
import os
import re
import shlex
import shutil
import struct
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

HOME = Path.home()
CFG = Path(os.environ.get("XDG_CONFIG_HOME") or HOME / ".config")
DATA = Path(os.environ.get("XDG_DATA_HOME") or HOME / ".local/share")
DATA_DIRS = [DATA] + [Path(d) for d in (os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share").split(":") if d]
MARK = "# caelestia4 (tools/keyring-switch.py):"
OLD_MARKS = ("# caelestia4: keys in gnome-keyring", "# caelestia4: --password-store", MARK)

FLAG = {"gnome": "gnome-libsecret", "kwallet": "kwallet6"}
STORE_OF = {"gnome-libsecret": "gnome", "gnome": "gnome", "gnome-keyring": "gnome", "gnome-libsecret-v2": "gnome",
            "kwallet": "kwallet", "kwallet5": "kwallet", "kwallet6": "kwallet", "basic": "basic"}
SHOWN = {"gnome": "gnome-keyring", "kwallet": "KWallet", "basic": "none (basic)", None: "?"}

# Electron's fuse wire: this sentinel, a version byte, a length byte, then one byte per fuse; EnableCookieEncryption is
# the second fuse (electron/fuses.json5)
FUSE_SENTINEL = b"dL7pKGdnNz796PbbjQWNKmHXBZaB9tsX"
SAFE_STORAGE_CALL = re.compile(rb"safeStorage\??\.(?:encryptString|decryptString|isEncryptionAvailable"
                               rb"|isAsyncEncryptionAvailable|encryptStringAsync|decryptStringAsync"
                               rb"|getSelectedStorageBackend)\b"
                               # minified code imports it under another name: import{safeStorage as P5}, {safeStorage:x}
                               rb"|import\s*\{[^}]{0,400}\bsafeStorage\s+as\s+[\w$]+|\{[^}]{0,200}\bsafeStorage\s*:\s*[\w$]+\s*[,}]")
# Browsers: the libsecret name is a build constant and the KWallet one the product name (os_crypt key_storage_*)
BROWSERS = [(re.compile(r"^brave"), "brave", "Brave"), (re.compile(r"^(google-)?chrome"), "chrome", "Chrome"),
            (re.compile(r"^chromium"), "chromium", "Chromium")]
PYKR = {"gnome": "keyring.backends.SecretService.Keyring", "kwallet": "keyring.backends.kwallet.DBusKeyring"}
PYKR_APP = "Python keyring library"
# KWallet folders that aren't python-keyring services: Chromium/Electron keys ("* Keys"), the Secret Service and
# portal folders, KDE's own
KWALLET_NOT_PYKR = {"Secret Service", "xdg-desktop-portal", "Passwords", "Form Data", "Network Management",
                    "kdewallet", "ksshaskpass", "Maps", "KMail", "Akonadi", "Kopete", "Konversation"}


def say(msg):
    print(f"\033[1;34m::\033[0m {msg}")


def warn(msg):
    print(f"\033[33m!!\033[0m {msg}")


# ---------------------------------------------------------------- desktop entries

def read_entry(path):
    """{group: {key: value}} of a desktop entry (keys as written, localised ones included)"""
    groups, cur = {}, None
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            cur = groups.setdefault(line[1:-1], {})
        elif cur is not None and "=" in line:
            k, v = line.split("=", 1)
            cur.setdefault(k.strip(), v.strip())
    return groups


def entry_files():
    """(desktop id, path, is_user) for every entry, the first of each id in XDG order"""
    seen = {}
    for base in DATA_DIRS:
        root = base / "applications"
        if not root.is_dir():
            continue
        for p in sorted(root.rglob("*.desktop")):
            did = str(p.relative_to(root)).replace("/", "-")
            seen.setdefault(did, (p, base == DATA))
    return [(did, p, user) for did, (p, user) in seen.items()]


def exec_argv(exec_line):
    """The command of an Exec line, field codes and an `env VAR=...` prefix dropped"""
    try:
        argv = shlex.split(exec_line)
    except ValueError:
        return []
    return [a for a in argv[program_index(argv):] if not re.fullmatch(r"%[a-zA-Z]", a)]


def program_index(argv):
    """Where the program is in an Exec command: after an `env [options] [NAME=value]...` prefix"""
    if not argv or os.path.basename(argv[0]) != "env":
        return 0
    i = 1
    while i < len(argv):
        a = argv[i]
        if a in ("-u", "--unset", "-C", "--chdir", "-S", "--split-string"):
            i += 2
        elif a == "--":
            return i + 1
        elif a.startswith("-") or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", a):
            i += 1
        else:
            break
    return i


def which(cmd):
    if not cmd:
        return None
    p = cmd if "/" in cmd else shutil.which(cmd)
    return os.path.realpath(p) if p and os.path.exists(p) else None


# ---------------------------------------------------------------- what an app runs

def is_elf(path):
    try:
        with open(path, "rb") as f:
            return f.read(4) == b"\x7fELF"
    except OSError:
        return False


def is_script(path):
    try:
        with open(path, "rb") as f:
            return f.read(2) == b"#!"
    except OSError:
        return False


def find_in(path, pattern):
    """Search a big file without reading it into memory: the first match, or None"""
    try:
        with open(path, "rb") as f, mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as m:
            if isinstance(pattern, bytes):
                i = m.find(pattern)
                return None if i < 0 else (i, m[i:i + len(pattern) + 40])
            hit = pattern.search(m)
            return None if hit is None else (hit.start(), hit.group(0))
    except (OSError, ValueError):
        return None


def electron_fuses(path):
    """None if not Electron, else whether its cookie-encryption fuse is on"""
    hit = find_in(path, FUSE_SENTINEL)
    if hit is None:
        return None
    wire = hit[1][len(FUSE_SENTINEL):]
    return len(wire) > 3 and wire[3:4] == b"1"


def expand(text, assigns):
    for _ in range(3):
        text = re.sub(r"\$\{([A-Za-z_][A-Za-z0-9_]*)(?::-[^}]*)?\}|\$([A-Za-z_][A-Za-z0-9_]*)",
                      lambda m: assigns.get(m.group(1) or m.group(2), m.group(0)), text)
    return text


def script_facts(path):
    """What a launcher script reads and runs: flags files (not the shared electronNN ones), the program it starts,
    its .asar, the VS Code family's app folder"""
    try:
        text = Path(path).read_text(errors="replace")
    except OSError:
        return {}
    assigns = {"XDG_CONFIG_HOME": str(CFG), "HOME": str(HOME)}
    for m in re.finditer(r"^\s*(?:export\s+|local\s+|readonly\s+)?([A-Za-z_][A-Za-z0-9_]*)=([\"']?)([^\"'\s;`]*)\2"
                         r"(?=\s*(?:$|;|&&|\|\||#))", text, re.M):
        if m.group(3) and "$(" not in m.group(3):
            assigns.setdefault(m.group(1), m.group(3))
    # a variable set from the script's own place ($(dirname "$0"), `dirname ...`): the script's folder or its parent,
    # tried after what the script assigns
    here = os.path.dirname(os.path.realpath(path))
    dirvars = {m.group(1) for m in re.finditer(r"\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?/", text)}
    dirvars -= {"XDG_CONFIG_HOME", "HOME", "XDG_DATA_HOME"}
    variants = [dict(assigns, **{v: here for v in dirvars if v not in assigns})]
    variants += [dict(assigns, **{v: d for v in dirvars}) for d in (here, os.path.dirname(here))]
    src = text.split("\n", 1)[1] if text.startswith("#!") else text
    body = "\n".join(expand(src, v) for v in variants)
    # flags files, also ones named through a variable (Arch's code: "${name}-flags.conf", name=code)
    flags = []
    for m in re.finditer(r"(?:\}|\.config|\$XDG_CONFIG_HOME)/([A-Za-z0-9_.@-][A-Za-z0-9_.@/-]*flags\.conf)\b",
                         src + "\n" + expand(src, assigns)):
        name = m.group(1)
        if not re.fullmatch(r"electron\d*-flags\.conf", name) and name not in flags:
            flags.append(name)
    targets, asar, appdir = [], None, None
    for m in re.finditer(r"(?<![\w.-])((?:/(?!dev/|proc/|sys/|tmp/\.)[^\s\"';|&)<>]+/[^\s\"';|&)<>]+)|electron\d+)"
                         r"(?=[\s\"';|&)]|$)", body, re.M):
        tok = m.group(1)
        if tok.endswith(".asar") and asar is None and os.path.exists(tok):
            asar = tok
        if appdir is None and os.path.exists(tok) and not tok.startswith(("/usr/bin/", "/usr/lib/electron")):
            appdir = product_dir(tok)  # /usr/share/cursor/resources/app/out/cli.js, /usr/lib/code/out/cli.js
        r = which(tok)
        if r and r != os.path.realpath(path) and os.access(r, os.X_OK) and os.path.isfile(r) \
                and (is_elf(r) or is_script(r)) and r not in targets:
            targets.append(r)
    # the program it hands over to: the last exec'd one, else the last one named
    execd = [which(m.group(1)) for m in re.finditer(r"\bexec\s+(?:-a\s+\S+\s+)?\"?((?:/[^\s\"';]+)|electron\d+)",
                                                     body)]
    execd = [t for t in execd if t in targets]
    return {"flags": flags, "next": (execd or targets or [None])[-1], "asar": asar, "appdir": appdir}


def elf_launcher(path):
    """A compiled launcher (Arch's chromium-launcher: /usr/bin/chromium reads chromium-flags.conf and runs
    /usr/lib/chromium/chromium): the flags file and the program named in its strings. None for anything else"""
    d = os.path.dirname(path)
    if os.path.exists(f"{d}/icudtl.dat") or electron_fuses(path) is not None:
        return None
    try:
        if os.path.getsize(path) > 32 << 20:
            return None
        data = Path(path).read_bytes()
    except OSError:
        return None
    flags = [m.decode() for m in dict.fromkeys(re.findall(rb"([A-Za-z0-9_.-]+-flags\.conf)\x00", data))
             if not re.fullmatch(rb"electron\d*-flags\.conf", m)]
    nxt = None
    for m in re.findall(rb"(/[A-Za-z0-9_.+/-]+/[A-Za-z0-9_.+-]+)\x00", data):
        p = m.decode()
        if os.path.isfile(p) and is_elf(p) and os.path.exists(f"{os.path.dirname(p)}/icudtl.dat"):
            nxt = os.path.realpath(p)
            break
    return {"flags": flags, "next": nxt, "asar": None, "appdir": None} if flags and nxt else None


def product_dir(path):
    """The VS Code family's app folder (product.json with a dataFolderName) holding path, if any"""
    p = Path(path)
    for d in [p] + list(p.parents)[:4]:
        f = d / "product.json"
        if f.is_file():
            try:
                if json.loads(f.read_text()).get("dataFolderName"):
                    return str(d)
            except (OSError, ValueError):
                return None
    return None


def asar_json(asar, name="package.json"):
    """A file at the root of an .asar, parsed: the header is a pickle (4, size) then (size, json size, json)"""
    try:
        with open(asar, "rb") as f:
            head = f.read(16)
            _, pickle_size, _, json_size = struct.unpack("<4I", head)
            header = json.loads(f.read(json_size))
            node = header["files"][name]
            if node.get("unpacked"):
                return json.loads(Path(asar + ".unpacked", name).read_text())
            f.seek(8 + pickle_size + int(node["offset"]))
            return json.loads(f.read(node["size"]))
    except (OSError, KeyError, ValueError, struct.error):
        return None


@dataclass
class App:
    name: str                      # what you type: status shows it
    did: str                       # its desktop id
    entry: Path                    # the entry it was found by
    kind: str                      # browser | electron | python-keyring
    chain: list                    # launcher scripts, then the program
    program: str = ""
    asar: str = None
    appdir: str = None
    keys: bool = True              # keeps a key in a store at all
    why: str = ""
    route: tuple = None            # ("argv", path) | ("flags", path) | ("desktop", path) | ("pykr", path)
    secret_app: str = None         # libsecret application=
    kwallet_name: str = None       # KWallet "<name> Keys" / "<name> Safe Storage"
    name_guessed: bool = False
    aliases: set = field(default_factory=set)
    bypass: list = field(default_factory=list)   # your entries that start it without the route
    other_entries: list = field(default_factory=list)


def classify(did, path, user, groups):
    de = groups.get("Desktop Entry", {})
    if de.get("Type", "Application") != "Application" or de.get("Hidden") == "true":
        return None
    argv = exec_argv(de.get("Exec", ""))
    if not argv or argv[0] in ("flatpak", "snap") or "/snap/" in argv[0]:
        return None
    start = which(argv[0])
    if not start:
        return None
    chain, flags_at, asar, appdir = [], {}, None, None
    cur = start
    for _ in range(6):
        chain.append(cur)
        if is_script(cur):
            facts = script_facts(cur)
        else:
            facts = elf_launcher(cur)
            if facts is None:
                break
        if facts.get("flags"):
            flags_at.setdefault(cur, facts["flags"])
        asar = asar or facts.get("asar")
        appdir = appdir or facts.get("appdir")
        nxt = facts.get("next")
        if not nxt or nxt in chain:
            break
        cur = nxt
    prog = chain[-1]
    if not is_elf(prog):
        return None
    # A system electron run on an .asar named after it in the Exec line (Vesktop's autostart entry)
    srcdir = None
    for a in argv[1:]:
        if a.endswith(".asar") and os.path.exists(a):
            asar = asar or a
        elif os.path.isfile(os.path.join(a, "package.json")):
            srcdir = srcdir or os.path.realpath(a)  # electron run on an unpacked app folder
    fuse = electron_fuses(prog)
    pdir = os.path.dirname(prog)
    if fuse is None:
        if not (os.path.exists(f"{pdir}/icudtl.dat") and os.path.exists(f"{pdir}/resources.pak")):
            return None
        kind = "browser"
    else:
        kind = "electron"
        if appdir is None and os.path.isfile(f"{pdir}/resources/app/product.json"):
            appdir = f"{pdir}/resources/app"
        if asar is None and os.path.isfile(f"{pdir}/resources/app.asar"):
            asar = f"{pdir}/resources/app.asar"
    short = re.sub(r"\.desktop$", "", did)
    app = App(name=short, did=did, entry=path, kind=kind, chain=chain, program=prog, asar=asar, appdir=appdir)
    app.flags_at = flags_at
    app.srcdir = srcdir
    app.user = user
    app.de_name = de.get("Name", "")
    app.argv0 = argv[0]
    if kind == "electron":
        uses = fuse
        why = "cookie encryption on" if fuse else ""
        if not uses:
            src = asar or appdir or srcdir
            if src and os.path.isdir(src):
                # the app's own code before its node_modules
                files = sorted(Path(src).rglob("*.js"), key=lambda f: ("node_modules" in f.parts, len(f.parts)))
                for js in files[:4000]:
                    if js.stat().st_size < 64 << 20 and find_in(js, SAFE_STORAGE_CALL):
                        uses, why = True, "uses safeStorage"
                        break
            elif src:
                for f in sorted(Path(src).parent.glob("*.asar")):
                    if find_in(f, SAFE_STORAGE_CALL):
                        uses, why = True, "uses safeStorage"
                        break
        app.keys, app.why = bool(uses), why or "no key: cookies unencrypted, no safeStorage"
    else:
        app.why = "browser"
    return app


def key_names(app, override=None):
    """libsecret application= and the KWallet folder prefix the app's os_crypt uses"""
    if override:
        # "lib" for both, or "lib,KWallet name" (a browser's two differ: chromium / Chromium)
        lib, _, kw = override.partition(",")
        app.secret_app, app.kwallet_name, app.name_guessed = lib, kw or lib, False
        return
    if app.kind == "browser":
        base = os.path.basename(app.argv0 if "/" not in app.argv0 else app.chain[0])
        for pat, lib, kw in BROWSERS:
            if pat.search(base) or pat.search(os.path.basename(app.program)):
                app.secret_app, app.kwallet_name = lib, kw
                return
        # an unbranded build (Thorium and the like) keeps Chromium's names; a branded one has its own: guessed either
        # way, so moving it needs --name
        app.secret_app, app.kwallet_name, app.name_guessed = "chromium", "Chromium", True
        return
    # Electron: app.getName(), i.e. package.json's productName, else its name, else the entry's Name
    pkg = None
    folder = app.appdir or getattr(app, "srcdir", None)
    if folder and os.path.isfile(f"{folder}/package.json"):
        try:
            pkg = json.loads(Path(folder, "package.json").read_text())
        except (OSError, ValueError):
            pkg = None
    elif app.asar:
        pkg = asar_json(app.asar)
    n = (pkg or {}).get("productName") or (pkg or {}).get("name")
    if app.appdir and os.path.isfile(f"{app.appdir}/product.json"):
        try:
            # the VS Code family names its key after nameShort ("Code Safe Storage", "VSCodium Safe Storage")
            n = json.loads(Path(app.appdir, "product.json").read_text()).get("nameShort") or n
        except (OSError, ValueError):
            pass
    if not n:
        n, app.name_guessed = app.de_name or app.name, True
    app.secret_app = app.kwallet_name = n


def pick_route(app):
    if app.appdir:
        try:
            folder = json.loads(Path(app.appdir, "product.json").read_text()).get("dataFolderName")
        except (OSError, ValueError):
            folder = None
        if folder:
            return ("argv", HOME / folder / "argv.json")
    for script in app.chain:
        for name in getattr(app, "flags_at", {}).get(script, []):
            return ("flags", CFG / name, script)
    return ("desktop", DATA / "applications" / app.did)


def discover():
    """The apps, one per program (+ .asar): a browser's web-app entries join the browser"""
    by_target = {}
    for did, path, user in entry_files():
        app = classify(did, path, user, read_entry(path))
        if app is None:
            continue
        key = (app.program, app.asar or app.appdir or app.srcdir)
        best = by_target.get(key)
        if best is None:
            by_target[key] = app
            continue
        # the main entry: the one through the most launcher scripts, then a shown one, then the shortest id
        score = lambda a: (len(a.chain), read_entry(a.entry).get("Desktop Entry", {}).get("NoDisplay") != "true",
                           -len(a.did))
        main, other = (app, best) if score(app) > score(best) else (best, app)
        main.other_entries += [other.entry] + other.other_entries
        by_target[key] = main
    apps = []
    for app in by_target.values():
        app.route = pick_route(app)
        key_names(app)
        app.aliases = {app.name.lower(), os.path.basename(app.argv0).lower(), app.de_name.lower(),
                       app.name.split(".")[-1].lower(), (app.secret_app or "").lower()}
        apps.append(app)
    # python-keyring: its own backend setting
    try:
        import keyring  # noqa: F401
        apps.append(App(name="python-keyring", did="", entry=Path(), kind="python-keyring", chain=[],
                        route=("pykr", CFG / "python_keyring/keyringrc.cfg"), aliases={"python-keyring", "keyring"},
                        why="python's keyring module"))
    except ImportError:
        pass
    # names: unique, short
    names = {}
    for app in apps:
        if app.kind == "python-keyring":
            continue
        cmd = os.path.basename(app.argv0)
        short = cmd.lower() if "/" not in app.argv0 and shutil.which(cmd) else \
            (app.name.split(".")[-1].lower() if app.name.count(".") >= 2 else app.name.lower())
        names.setdefault(short, []).append(app)
    for short, group in names.items():
        for app in group:
            app.name = short if len(group) == 1 else app.name.lower()
    # your own entries that start the program without going through the route
    user_files = list((DATA / "applications").glob("*.desktop")) + list((CFG / "autostart").glob("*.desktop"))
    for app in apps:
        if app.kind == "python-keyring":
            continue
        route_path = app.route[1]
        if app.route[0] == "flags":
            past = app.chain[app.chain.index(app.route[2]) + 1:]
        elif app.route[0] == "argv":
            past = []
        else:
            past = app.chain
        for f in user_files:
            if f == route_path:
                continue
            for exec_line in exec_lines(f):
                r = which((exec_argv(exec_line) or [""])[0])
                if not r:
                    continue
                own = ident(app)
                if is_shared(r) or (own and r == app.program):
                    # a shared electron (its wrapper or the binary): only an entry naming this app's code starts it
                    hit = bool(own) and own in exec_line and (app.route[0] == "desktop" or r not in app.chain[:1])
                else:
                    hit = r in past
                if hit:
                    app.bypass.append(f)
                    break
    return apps


def ident(app):
    """The path that tells this app apart when its program is a shared electron"""
    return app.asar or app.appdir or getattr(app, "srcdir", None)


def is_shared(path):
    """A system electron, run by many apps: /usr/lib/electronNN/electron or its /usr/bin/electronNN wrapper"""
    return re.search(r"(?:/electron\d*/electron|/bin/electron\d*)$", path or "") is not None


def shared_program(app):
    return is_shared(app.program)


def exec_lines(path):
    try:
        return [l[5:] for l in path.read_text(errors="replace").splitlines() if l.startswith("Exec=")]
    except OSError:
        return []


# ---------------------------------------------------------------- where each app's store is set

def session_desktop():
    """XDG_CURRENT_DESKTOP of the session the apps run in: KEYRING_SWITCH_DESKTOP (the installer names Hyprland), else
    what the Hyprland session's uwsm env files export, else this shell's"""
    if os.environ.get("KEYRING_SWITCH_DESKTOP"):
        return os.environ["KEYRING_SWITCH_DESKTOP"]
    found = None
    for f in sorted((CFG / "uwsm/env-hyprland.d").glob("*.sh")) + [CFG / "uwsm/env-hyprland", CFG / "uwsm/env"]:
        try:
            for m in re.finditer(r"^\s*export\s+XDG_CURRENT_DESKTOP=[\"']?([^\"'\s]+)", f.read_text(), re.M):
                found = m.group(1)
        except OSError:
            continue
    return found or os.environ.get("XDG_CURRENT_DESKTOP", "")


def desktop_default():
    """The store an app with no --password-store uses for its key. Chromium's key provider (cookies, passwords, and
    Electron's async safeStorage) takes KWallet on KDE and libsecret everywhere else, Hyprland included; only Electron's
    sync safeStorage.encryptString falls to "basic" there, which is why the flag is set anyway"""
    return "kwallet" if "KDE" in session_desktop().upper().split(":") else "gnome"


def flag_in(text):
    m = re.findall(r"--password-store(?:=|\s+)([A-Za-z0-9-]+)", text)
    return m[-1] if m else None


def current_store(app):
    return store_set(app)[0]


def store_set(app):
    """(store, whether a file names it); with none named, what the desktop gives it"""
    kind, path = app.route[0], app.route[1]
    val = None
    if kind == "argv":
        if path.exists():
            m = re.search(r'"password-store"\s*:\s*"([^"]*)"', strip_jsonc(path.read_text()))
            val = m.group(1) if m else None
    elif kind == "flags":
        if path.exists():
            val = flag_in("\n".join(l for l in path.read_text().splitlines() if not l.lstrip().startswith("#")))
    elif kind == "desktop":
        files = [path] if path.exists() else [app.entry]
        val = flag_in("\n".join(exec_lines(files[0])))
    elif kind == "pykr":
        env = os.environ.get("PYTHON_KEYRING_BACKEND")
        cfg = ""
        if path.exists():
            m = re.search(r"^\s*default-keyring\s*=\s*(\S+)", path.read_text(), re.M)
            cfg = m.group(1) if m else ""
        b = env or cfg
        if "kwallet" in b.lower():
            return "kwallet", True
        if "secretservice" in b.lower():
            return "gnome", True
        return ("gnome" if desktop_default() != "kwallet" else "kwallet"), False
    if val is None:
        # a flag in the shared electronNN-flags.conf counts when the app's own route has none
        for script in app.chain:
            m = re.match(r"electron(\d+)$", os.path.basename(script))
            if m:
                for name in (f"electron{m.group(1)}-flags.conf", "electron-flags.conf"):
                    f = CFG / name
                    if f.exists():
                        val = flag_in(f.read_text())
                        break
        return (STORE_OF.get(val, desktop_default()), True) if val else (desktop_default(), False)
    return STORE_OF.get(val, "?"), True


def strip_jsonc(text):
    return re.sub(r'("(?:\\.|[^"\\])*")|//[^\n]*|/\*.*?\*/', lambda m: m.group(1) or "", text, flags=re.S)


# ---------------------------------------------------------------- the two stores, through the Secret Service API

class StillLocked(Exception):
    """A dry run met a locked store: it doesn't unlock (no password dialog for a dry run)"""


class Stores:
    def __init__(self, dry=False):
        self.dry = dry
        try:
            self.bus = Gio.bus_get_sync(Gio.BusType.SESSION)
        except GLib.Error:
            sys.exit("no session bus (run this inside your desktop session): nothing changed")
        self.sessions = {}

    def call(self, name, path, iface, method, sig, args, ret, timeout=60000):
        return self.bus.call_sync(name, path, iface, method, GLib.Variant(sig, args) if sig else None,
                                  GLib.VariantType(ret), Gio.DBusCallFlags.NONE, timeout, None).unpack()

    def prop(self, name, path, iface, key):
        return self.call(name, path, "org.freedesktop.DBus.Properties", "Get", "(ss)", (iface, key), "(v)")[0]

    def owner(self, name):
        try:
            pid = self.call("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                            "GetConnectionUnixProcessID", "(s)", (name,), "(u)")[0]
            return Path(f"/proc/{pid}/comm").read_text().strip()
        except (GLib.Error, OSError):
            return None

    def activatable(self, name):
        try:
            return name in self.call("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                                     "ListActivatableNames", None, None, "(as)")[0]
        except GLib.Error:
            return False

    def service(self, store):
        """The bus name holding a store. KWallet 6 keeps its entries in ksecretd, or, with [KSecretD] Enabled=false,
        in whatever serves org.freedesktop.secrets (kwalletd6 is a shim over one of them)"""
        if store == "gnome":
            return "org.freedesktop.secrets"
        r = subprocess.run(["kreadconfig6", "--file", "kwalletrc", "--group", "KSecretD", "--key", "Enabled"],
                           capture_output=True, text=True) if shutil.which("kreadconfig6") else None
        if r and r.stdout.strip().lower() == "false":
            return "org.freedesktop.secrets"
        return "org.kde.secretservicecompat"

    def available(self, store):
        name = self.service(store)
        return self.owner(name) is not None or self.activatable(name)

    def session(self, name):
        if name not in self.sessions:
            self.sessions[name] = self.call(name, "/org/freedesktop/secrets", "org.freedesktop.Secret.Service",
                                            "OpenSession", "(sv)", ("plain", GLib.Variant("s", "")), "(vo)")[1]
        return self.sessions[name]

    def search(self, store, attrs):
        """(unlocked, locked) item paths"""
        name = self.service(store)
        return self.call(name, "/org/freedesktop/secrets", "org.freedesktop.Secret.Service", "SearchItems",
                         "(a{ss})", (attrs,), "(aoao)")

    def unlock(self, name, paths):
        _, prompt = self.call(name, "/org/freedesktop/secrets", "org.freedesktop.Secret.Service", "Unlock", "(ao)",
                              (paths,), "(aoo)")
        if prompt == "/":
            return
        loop, result = GLib.MainLoop(), {}

        def done(_c, _s, _p, _i, _sig, params):
            result["dismissed"] = params.unpack()[0]
            loop.quit()

        sub = self.bus.signal_subscribe(name, "org.freedesktop.Secret.Prompt", "Completed", prompt, None,
                                        Gio.DBusSignalFlags.NONE, done)
        print(f"   {'KWallet' if 'kde' in name else 'the keyring'} is locked: unlock it in the dialog")
        self.call(name, prompt, "org.freedesktop.Secret.Prompt", "Prompt", "(s)", ("",), "()")
        loop.run()
        self.bus.signal_unsubscribe(sub)
        if result.get("dismissed"):
            sys.exit("the unlock dialog was dismissed: nothing more was changed")

    def read(self, store, attrs):
        """[(path, label, attributes, value)] of the items matching attrs, unlocking them if need be"""
        name = self.service(store)
        unlocked, locked = self.search(store, attrs)
        if locked and self.dry:
            raise StillLocked(store)
        if locked:
            self.unlock(name, list(locked))
            unlocked, locked = self.search(store, attrs)
        out = []
        for path in unlocked:
            label = self.prop(name, path, "org.freedesktop.Secret.Item", "Label")
            a = dict(self.prop(name, path, "org.freedesktop.Secret.Item", "Attributes"))
            value = bytes(self.call(name, path, "org.freedesktop.Secret.Item", "GetSecret", "(o)",
                                    (self.session(name),), "((oayays))")[0][2])
            out.append((path, label, a, value))
        return out

    def collection(self, store):
        """The store's default keyring / wallet; never gnome-keyring's in-memory "session" collection"""
        name = self.service(store)
        (coll,) = self.call(name, "/org/freedesktop/secrets", "org.freedesktop.Secret.Service", "ReadAlias", "(s)",
                            ("default",), "(o)")
        if coll == "/" or coll.endswith("/session"):
            sys.exit(f"{SHOWN[store]} has no default keyring/wallet yet (gnome-keyring: log in again through the "
                     f"login screen, its PAM creates it; KWallet: its first-use wizard): nothing more was changed")
        if self.prop(name, coll, "org.freedesktop.Secret.Collection", "Locked"):
            self.unlock(name, [coll])
        return name, coll

    def get(self, name, path):
        return bytes(self.call(name, path, "org.freedesktop.Secret.Item", "GetSecret", "(o)", (self.session(name),),
                               "((oayays))")[0][2])

    def put(self, store, label, attrs, search, value):
        """Make every item the app's lookup (search) finds hold value: the existing ones overwritten in place (an
        entry with other attributes would otherwise stay beside the new one, and be the one read), else a new one.
        Then each is read back"""
        name, coll = self.collection(store)
        unlocked, locked = self.search(store, search)
        if locked:
            self.unlock(name, list(locked))
            unlocked, locked = self.search(store, search)
        secret = (self.session(name), b"", value, "text/plain")
        if unlocked:
            for path in unlocked:
                self.call(name, path, "org.freedesktop.Secret.Item", "SetSecret", "((oayays))", (secret,), "()")
        else:
            props = {"org.freedesktop.Secret.Item.Label": GLib.Variant("s", label),
                     "org.freedesktop.Secret.Item.Attributes": GLib.Variant("a{ss}", attrs)}
            _, prompt = self.call(name, coll, "org.freedesktop.Secret.Collection", "CreateItem",
                                  "(a{sv}(oayays)b)", (props, secret, False), "(oo)")
            if prompt != "/":
                sys.exit(f"{SHOWN[store]} asked for a prompt to store {label!r}: unlock it and run this again")
        unlocked, locked = self.search(store, search)
        if not unlocked or locked or any(self.get(name, p) != value for p in unlocked):
            sys.exit(f"read-back mismatch for {label!r} in {SHOWN[store]}: stopped before pointing the app at it")

    def keep(self, store, label, search, value, stamp):
        """A key about to be replaced, kept under attributes no app looks up; one copy per distinct value"""
        name, coll = self.collection(store)
        b_search = {"xdg:schema": "org.caelestia4.replaced", **{f"replaced-{k}": v for k, v in search.items()}}
        for path in self.search(store, b_search)[0]:
            if self.get(name, path) == value:
                return False
        props = {"org.freedesktop.Secret.Item.Label": GLib.Variant("s", f"{label} (replaced {stamp})"),
                 "org.freedesktop.Secret.Item.Attributes": GLib.Variant("a{ss}", {**b_search, "replaced-at": stamp})}
        item, prompt = self.call(name, coll, "org.freedesktop.Secret.Collection", "CreateItem", "(a{sv}(oayays)b)",
                                 (props, (self.session(name), b"", value, "text/plain"), False), "(oo)")
        if prompt != "/" or self.get(name, item) != value:
            sys.exit(f"couldn't keep the old {label!r} in {SHOWN[store]}: stopped, nothing replaced")
        return True


def kw_attrs(folder, key):
    """How kwalletd6 6.x stores writePassword(folder, key): its readPassword matches server, user and type"""
    return {"server": folder, "user": key, "type": "plaintext", "xdg:schema": "org.qt.keychain"}


def key_refs(app):
    """{store: [(label, search attributes, write attributes)]} of the app's own key, first the one that matters"""
    if app.kind == "python-keyring":
        return {}
    lib = app.secret_app
    kw = app.kwallet_name
    refs = {"gnome": [(f"{kw} Safe Storage", {"application": lib},
                       {"application": lib, "xdg:schema": "chrome_libsecret_os_crypt_password_v2"})],
            "kwallet": [(f"{kw} Keys/{kw} Safe Storage", {"server": f"{kw} Keys", "user": f"{kw} Safe Storage",
                                                            "type": "plaintext"}, kw_attrs(f"{kw} Keys",
                                                                                           f"{kw} Safe Storage"))]}
    if app.kind == "electron":
        # Electron 43+'s sync safeStorage under KWallet: one entry shared by every Electron app
        refs["kwallet"].append(("Chromium Keys/Chromium Safe Storage",
                                {"server": "Chromium Keys", "user": "Chromium Safe Storage", "type": "plaintext"},
                                kw_attrs("Chromium Keys", "Chromium Safe Storage")))
    return refs


def presence(stores, store, attrs):
    """'yes', 'locked' (there, not readable without unlocking) or 'no', without unlocking anything"""
    try:
        if not stores.available(store):
            return "n/a"
        unlocked, locked = stores.search(store, attrs)
        return "yes" if unlocked else ("locked" if locked else "no")
    except GLib.Error:
        return "n/a"


# ---------------------------------------------------------------- writing an app's route

RESERVED = set(" \t\n\"'\\><~|&;$*?#()`")


def exec_quote(arg):
    """An argument as the desktop entry spec wants it: quoted when it has a reserved character"""
    if re.fullmatch(r"%[a-zA-Z]", arg) or not (set(arg) & RESERVED) and arg:
        return arg
    return '"' + re.sub(r'(["`$\\])', r"\\\1", arg) + '"'


def set_flag_in_exec(line, flag):
    """An Exec line with --password-store=flag right after the program (an `env [-u NAME] [NAME=value]` prefix kept
    in front, any earlier --password-store replaced)"""
    if not line.startswith("Exec="):
        return line
    try:
        argv = shlex.split(line[5:])
    except ValueError:
        return line
    i = program_index(argv)
    if i >= len(argv):
        return line
    rest, skip = [], False
    for a in argv[i + 1:]:
        if skip:
            skip = False
            continue
        if a == "--password-store":
            skip = True
            continue
        if a.startswith("--password-store="):
            continue
        rest.append(a)
    return "Exec=" + " ".join(exec_quote(a) for a in argv[:i + 1] + [f"--password-store={flag}"] + rest)


def write_desktop(path, source, flag, store, note):
    text = (path if path.exists() else source).read_text(errors="replace")
    lines = [l for l in text.splitlines() if not l.startswith(OLD_MARKS)
             and not re.match(r"^X-[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*-Generated=", l)]
    lines = [set_flag_in_exec(l, flag) if l.startswith("Exec=") else l for l in lines]
    lines.insert(0, f"{MARK} keys in {SHOWN[store]}{note}. Re-run it after the app's update to refresh this copy.")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n")


def write_flags_file(path, flag, store):
    lines = path.read_text().splitlines() if path.exists() else []
    out = []
    for l in lines:
        if l.startswith(OLD_MARKS):
            continue
        if not l.lstrip().startswith("#"):
            l = re.sub(r"(^|\s)--password-store(?:=\S+|\s+(?!-)\S+)", "", l).strip() if "--password-store" in l else l
            if not l and lines:
                continue
        out.append(l)
    out += [f"{MARK} keys in {SHOWN[store]}", f"--password-store={flag}"]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(out) + "\n")


def write_argv(path, flag):
    """~/<data folder>/argv.json (JSON with comments): its password-store key set, the rest kept as written"""
    text = path.read_text() if path.exists() else "{\n}\n"
    if re.search(r'"password-store"\s*:', strip_jsonc(text)):
        text = re.sub(r'("password-store"\s*:\s*)"[^"]*"', lambda m: f'{m.group(1)}"{flag}"', text, count=1)
    else:
        body = strip_jsonc(text)
        empty = re.fullmatch(r"\s*\{\s*\}\s*", body) is not None
        i = text.index("{") + 1
        text = text[:i] + f'\n\t// {MARK[2:]} where the keys are\n\t"password-store": "{flag}"' + \
            ("\n" if empty else ",") + text[i:]
    json.loads(re.sub(r",(\s*[}\]])", r"\1", strip_jsonc(text)))  # still JSON
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def write_pykr(path, store):
    text = path.read_text() if path.exists() else ""
    line = f"default-keyring = {PYKR[store]}"
    if re.search(r"^\s*default-keyring\s*=", text, re.M):
        text = re.sub(r"^\s*default-keyring\s*=.*$", line, text, count=1, flags=re.M)
    elif re.search(r"^\[backend\]\s*$", text, re.M):
        text = re.sub(r"^\[backend\]\s*$", f"[backend]\n{line}", text, count=1, flags=re.M)
    else:
        text = (text.rstrip("\n") + "\n\n" if text.strip() else "") + f"{MARK} keys in {SHOWN[store]}\n[backend]\n{line}\n"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def write_route(app, store):
    flag = FLAG[store]
    kind, path = app.route[0], app.route[1]
    if kind == "argv":
        write_argv(path, flag)
    elif kind == "flags":
        write_flags_file(path, flag, store)
    elif kind == "desktop":
        write_desktop(path, app.entry, flag, store, "; the app leaves this copy alone (no generated-by mark)")
    elif kind == "pykr":
        write_pykr(path, store)
    for f in app.bypass:
        write_desktop(f, f, flag, store, f"; it starts {app.name} without its launcher")
    if kind == "desktop" or app.bypass:
        if shutil.which("update-desktop-database"):
            subprocess.run(["update-desktop-database", str(DATA / "applications")], capture_output=True)


# ---------------------------------------------------------------- moving the keys

def plan_key(stores, app, src, dst, chromium_browser=False):
    """(actions, notes, go): actions are ("keep", label, search, value, note) for a target key about to be replaced
    and ("put", label, attrs, search, value, note); go=False when moving would lose the app's data. Values stay in
    memory"""
    refs = key_refs(app)
    actions, notes = [], []
    if src == dst or src not in refs:
        return actions, notes, True
    if not stores.available(src):
        notes.append(f"{SHOWN[src]} isn't running or installed: {app.name}'s old key can't be read; it starts with "
                     f"a new key in {SHOWN[dst]} (sign in again)")
        return actions, notes, True
    found = []
    for label, search, _ in refs[src]:
        items = stores.read(src, search)
        vals = list(dict.fromkeys(v for *_, v in items))
        if len(vals) > 1:
            notes.append(f"{SHOWN[src]} has {len(vals)} different keys for {label!r}: the first one is used")
        found.append(vals[0] if vals else None)
    value = next((v for v in found if v is not None), None)
    if value is None:
        notes.append(f"no key for {app.name} in {SHOWN[src]} (it never stored one there): nothing to carry over")
        return actions, notes, True
    if len(found) > 1 and None not in found[:2] and found[0] != found[1]:
        notes.append(f"{app.name} has two KWallet keys (its own and Electron's shared Chromium one): its own goes "
                     f"over; what it encrypted with the shared one (safeStorage.encryptString) won't open")
    for i, (label, search, attrs) in enumerate(refs[dst]):
        shared = search.get("server") == "Chromium Keys"
        old = list(dict.fromkeys(v for *_, v in stores.read(dst, search)))
        if old == [value]:
            notes.append(f"{label!r} in {SHOWN[dst]}: already the same key")
            continue
        if shared and old:
            if i == 0:
                # Chromium itself: its own KWallet entry is the one every Electron app on KWallet shares
                notes.append(f"KWallet's 'Chromium Keys' entry holds another key (the Electron apps on KWallet use "
                             f"it): {app.name} would lose its passwords and cookies there; not moved")
                return [], notes, False
            notes.append(f"KWallet's shared Electron key ('Chromium Keys') differs and other Electron apps may use "
                         f"it: kept; what {app.name} encrypted with safeStorage.encryptString won't open under KWallet")
            continue
        if shared and app.kind == "electron" and chromium_browser:
            notes.append(f"'Chromium Keys' is left for the Chromium browser: what {app.name} encrypted with "
                         f"safeStorage.encryptString won't open under KWallet")
            continue
        for v in old:
            actions.append(("keep", label, search, v, f"the different {label!r} already in {SHOWN[dst]}, kept aside"))
        actions.append(("put", label, attrs, search, value, f"{label!r} into {SHOWN[dst]}"))
    return actions, notes, True


def plan_pykr(stores, src, dst):
    """python-keyring's items, SecretService form {application, service, username} <-> KWallet folder service, entry
    username (what its DBusKeyring writes)"""
    actions, notes = [], []
    if src == dst or not stores.available(src):
        return actions, notes, True
    pairs = []
    if src == "gnome":
        for _, label, a, v in stores.read("gnome", {"application": PYKR_APP}):
            if a.get("service") and a.get("username"):
                pairs.append((a["service"], a["username"], v))
    else:
        # KWallet doesn't record which program wrote an entry: every plaintext one outside the browsers' and KDE's
        # folders, each listed
        for _, label, a, v in stores.read("kwallet", {"type": "plaintext"}):
            s, u = a.get("server"), a.get("user")
            if s and u and not s.endswith(" Keys") and s not in KWALLET_NOT_PYKR:
                pairs.append((s, u, v))
    for s, u, v in pairs:
        if dst == "kwallet":
            label, attrs, search = f"{s}/{u}", kw_attrs(s, u), {"server": s, "user": u, "type": "plaintext"}
        else:
            search = {"application": PYKR_APP, "service": s, "username": u}
            label, attrs = f"Password for '{u}' on '{s}'", search
        old = list(dict.fromkeys(x for *_, x in stores.read(dst, search)))
        if old == [v]:
            continue
        for x in old:
            actions.append(("keep", label, search, x, f"the different python-keyring {s}/{u} in {SHOWN[dst]}, kept aside"))
        actions.append(("put", label, attrs, search, v, f"python-keyring {s}/{u} into {SHOWN[dst]}"))
    if not pairs:
        notes.append(f"no python-keyring items in {SHOWN[src]}")
    return actions, notes, True


def running(app):
    for p in Path("/proc").iterdir():
        if not p.name.isdigit():
            continue
        try:
            if os.readlink(p / "exe") != app.program:
                continue
            own = ident(app)
            if own:
                if own.encode() in (p / "cmdline").read_bytes():
                    return True
            elif not shared_program(app):
                return True
        except OSError:
            continue
    return False


def select(apps, names, all_):
    if all_:
        return [a for a in apps if a.keys]
    out = []
    for n in names:
        hits = [a for a in apps if n.lower() == a.name or n.lower() in a.aliases]
        if not hits:
            sys.exit(f"no app called {n!r}: tools/keyring-switch.py status lists them")
        if len(hits) > 1:
            sys.exit(f"{n!r} matches {', '.join(a.name for a in hits)}: use one of these names")
        out += [h for h in hits if h not in out]
    return out


def cmd_status(args):
    apps = discover()
    stores = Stores()
    shown = select(apps, args.apps, False) if args.apps else apps
    ss = stores.owner("org.freedesktop.secrets")
    kw = stores.owner("org.kde.secretservicecompat") or ("activatable" if stores.activatable(
        "org.kde.secretservicecompat") else None)
    say(f"Secret Service (gh, Zed, the shell's keys, libsecret apps): {ss or 'nobody'}; KWallet: "
        f"{'ksecretd ' + (kw if kw != 'ksecretd' else 'running') if kw else 'not installed'}"
        f"{'' if stores.service('kwallet') != 'org.freedesktop.secrets' else ' (entries kept in ' + str(ss) + ')'}")
    say(f"an app with no store set keeps its key in {SHOWN[desktop_default()]} (XDG_CURRENT_DESKTOP="
        f"{session_desktop()}); Electron's safeStorage.encryptString has none there unless the store is set")
    rows = []
    for a in sorted(shown, key=lambda a: (not a.keys, a.name)):
        if a.kind == "python-keyring":
            cur, named = store_set(a)
            rows.append((a.name, a.kind, SHOWN[cur] + ("" if named else " (default)"),
                         f"{a.route[1]}".replace(str(HOME), "~"), "-", "-"))
            continue
        cur, named = store_set(a)
        refs = key_refs(a)
        g = presence(stores, "gnome", refs["gnome"][0][1]) if a.keys else "-"
        k = presence(stores, "kwallet", refs["kwallet"][0][1]) if a.keys else "-"
        where = {"argv": "argv.json", "flags": "flags file", "desktop": "desktop copy"}[a.route[0]]
        loc = f"{where} {str(a.route[1]).replace(str(HOME), '~')}"
        rows.append((a.name, a.kind if a.keys else f"{a.kind}, {a.why}",
                     SHOWN[cur] + ("" if named else " (default)") + ("" if a.keys else " (unused)"), loc, g, k))
        for f in a.bypass:
            rows.append(("", "  also started by", "", str(f).replace(str(HOME), "~"), "", ""))
        if a.keys and a.name_guessed:
            rows.append(("", f"  key name guessed: {a.secret_app}", "", "--name NAME if it's wrong", "", ""))
    head = ("app", "kind", "store now", "set in", "key: gnome", "KWallet")
    w = [max(len(str(r[i])) for r in rows + [head]) for i in range(6)]
    for r in [head] + rows:
        print("  " + "  ".join(str(c).ljust(w[i]) for i, c in enumerate(r)).rstrip())
    print("\n'locked': the key is there; its value is only read (and KWallet asks for its password) when an app is "
          "moved.")


def cmd_set(args):
    dst = args.store
    apps = discover()
    chosen = select(apps, args.apps, args.all)
    if not chosen:
        sys.exit("name the apps to move, or --all")
    if args.name and len(chosen) == 1:
        key_names(chosen[0], args.name)
    elif args.name:
        sys.exit("--name goes with one app")
    # apps reading one file (VSCodium and Code - OSS both read ~/.vscode-oss/argv.json) move together
    for app in chosen:
        if app.kind == "python-keyring":
            continue
        others = [a for a in apps if a not in chosen and a.keys and a.kind != "python-keyring"
                  and a.route[1] == app.route[1]]
        if others and not args.unset_only:
            sys.exit(f"{app.name} and {', '.join(a.name for a in others)} read their store from the same file "
                     f"({app.route[1]}): move them together (name them all). Nothing changed")
    stores = Stores(dry=args.dry_run)
    if not stores.available(dst):
        sys.exit(f"{SHOWN[dst]} isn't installed or can't start here: nothing changed")
    if dst == "kwallet" and stores.owner("org.kde.kwalletd6") is None and not stores.activatable("org.kde.kwalletd6"):
        sys.exit("kwalletd6 isn't installed (the apps' kwallet6 store talks to it): nothing changed")
    chromium_browser = any(a.kind == "browser" and a.kwallet_name == "Chromium" and not a.name_guessed for a in apps)
    stamp = time.strftime("%Y-%m-%d %H:%M:%S")
    held_back = []
    for app in chosen:
        src, named = store_set(app)
        if args.unset_only:
            # the installer's pass: only apps no file sets, already using dst by default, with no key elsewhere
            if named or src != dst or not app.keys or app.name_guessed:
                continue
            refs = key_refs(app)
            other = "kwallet" if dst == "gnome" else "gnome"
            if refs and presence(stores, dst, refs[dst][0][1]) == "no" and \
                    presence(stores, other, refs[other][0][1]) in ("yes", "locked"):
                warn(f"{app.name} has no store set but its key is in {SHOWN[other]}: left as it is "
                     f"(tools/keyring-switch.sh set gnome|kwallet {app.name})")
                continue
        say(f"{app.name}: {SHOWN[src]}{'' if named else ' (default)'} -> {SHOWN[dst]}")
        if not app.keys:
            print(f"   {app.why}: switching it changes nothing; skipped")
            continue
        if app.name_guessed:
            warn(f"{app.name}: its key name isn't known (guessed {app.secret_app}"
                 f"{'' if app.secret_app == app.kwallet_name else ' / ' + app.kwallet_name}); skipped. Give it: "
                 f"--name LIBSECRET_APP[,KWALLET_NAME]")
            held_back.append(app.name)
            continue
        try:
            if app.kind == "python-keyring":
                actions, notes, go = plan_pykr(stores, src, dst)
            else:
                actions, notes, go = plan_key(stores, app, src, dst, chromium_browser)
        except StillLocked as e:
            actions, notes, go = [], [f"{SHOWN[e.args[0]]} is locked: a dry run doesn't unlock it, so the keys aren't "
                                      f"compared; the real run asks for its password and compares them first"], True
        for n in notes:
            print(f"   {n}")
        if not go:
            held_back.append(app.name)
            continue
        for act in actions:
            print(f"   {'would write' if args.dry_run else 'writing'} {act[-1]}")
            if args.dry_run:
                continue
            if act[0] == "keep":
                stores.keep(dst, act[1], act[2], act[3], stamp)
            else:
                stores.put(dst, act[1], act[2], act[3], act[4])
        where = str(app.route[1]).replace(str(HOME), "~")
        print(f"   {'would set' if args.dry_run else 'setting'} {FLAG.get(dst) if app.kind != 'python-keyring' else PYKR[dst]}"
              f" in {where}" + "".join(f", {str(f).replace(str(HOME), '~')}" for f in app.bypass))
        if not args.dry_run:
            write_route(app, dst)
            if app.kind != "python-keyring" and running(app):
                warn(f"{app.name} is running: quit it fully (tray icon too), it reads its store when it starts")
    if args.dry_run:
        say("dry run: nothing was changed")
    if held_back:
        sys.exit(f"not moved: {', '.join(held_back)}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("status")
    s.add_argument("apps", nargs="*")
    s.set_defaults(func=cmd_status)
    t = sub.add_parser("set")
    t.add_argument("store", choices=["gnome", "kwallet"])
    t.add_argument("apps", nargs="*")
    t.add_argument("--all", action="store_true")
    t.add_argument("--dry-run", action="store_true")
    t.add_argument("--name", help="the app's key name: LIBSECRET_APP or LIBSECRET_APP,KWALLET_NAME")
    t.add_argument("--unset-only", action="store_true",
                   help="only apps whose store no file names and that have no key anywhere yet (the installer's)")
    t.set_defaults(func=cmd_set)
    args = p.parse_args()
    if os.geteuid() == 0:
        sys.exit("Run as your user, not root.")
    if os.environ.get("XDG_CONFIG_HOME") and os.path.realpath(os.environ["XDG_CONFIG_HOME"]) != \
            os.path.realpath(HOME / ".config") and not os.environ.get("KEYRING_SWITCH_TEST"):
        sys.exit("XDG_CONFIG_HOME isn't ~/.config: this desktop only works with its config there. Nothing changed.")
    args.func(args)


if __name__ == "__main__":
    main()

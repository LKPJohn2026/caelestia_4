#!/usr/bin/env python3
"""Tests for tools/keyring-switch.py and tools/kwallet-to-keyring.py on a fake HOME, with no session bus: no keyring
or wallet is ever reached, nothing outside a temporary directory is read or written but the scripts themselves.

  1. discover() on fake apps (a Chromium-style browser and your autostart entry for it, an Electron app with a launcher
     script and a flags file, a VS Code-style app with argv.json, an Electron app with no key): what each is, where its
     store is set, its key names
  2. the plan (plan_key) against in-memory stores: what would be written, kept aside, or held back
  3. write_route: each file edited as expected, your own lines kept, the same result when run again, and back
  4. the commands with no session bus: a message and exit 1, no traceback, no file changed (with PyGObject when it's
     installed, and always with a stand-in gi module, so this runs on any machine)

Usage: python3 -I tools/tests/keyring-switch/run.py
"""
import hashlib
import importlib.util
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import types
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
SWITCH = REPO / "tools/keyring-switch.py"
KW2GK = REPO / "tools/kwallet-to-keyring.py"
fails = 0


def ok(msg):
    print(f"ok: {msg}")


def bad(msg):
    global fails
    fails += 1
    print(f"FAIL: {msg}")


def check(cond, msg, detail=""):
    if cond:
        ok(msg)
    else:
        bad(msg + (f": {detail}" if detail else ""))


# ---------------------------------------------------------------- a stand-in for PyGObject: no bus anywhere

FAKE_GI = '''
import types
def require_version(*a):
    pass
'''
FAKE_REPOSITORY = '''
import types
class _Error(Exception):
    def __init__(self, message=""):
        super().__init__(message)
        self.message = message
def _no_bus(*a, **k):
    raise _Error("Could not connect: No such file or directory (stand-in gi: there is no session bus)")
GLib = types.SimpleNamespace(Error=_Error, GError=_Error, Variant=lambda *a: a, VariantType=lambda *a: a,
                             MainLoop=object)
Gio = types.SimpleNamespace(bus_get_sync=_no_bus, BusType=types.SimpleNamespace(SESSION=1),
                            DBusCallFlags=types.SimpleNamespace(NONE=0), DBusSignalFlags=types.SimpleNamespace(NONE=0))
'''


def fake_gi(root):
    d = root / "fakegi/gi/repository"
    d.mkdir(parents=True)
    (root / "fakegi/gi/__init__.py").write_text(FAKE_GI)
    (d / "__init__.py").write_text(FAKE_REPOSITORY)
    return root / "fakegi"


# ---------------------------------------------------------------- fake apps

SENTINEL = b"dL7pKGdnNz796PbbjQWNKmHXBZaB9tsX"


def elf(path, fuse=None):
    """An executable that looks like an ELF program; with fuse, an Electron one with that cookie-encryption fuse"""
    data = b"\x7fELF" + b"\0" * 60
    if fuse is not None:
        data += SENTINEL + b"\x01\x02" + b"1" + (b"1" if fuse else b"0") + b"\0" * 40
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    path.chmod(0o755)


def asar(path, files):
    """An .asar holding these files (name: bytes) at its root"""
    header, blob = {"files": {}}, b""
    for name, data in files.items():
        header["files"][name] = {"size": len(data), "offset": str(len(blob))}
        blob += data
    hj = json.dumps(header).encode()
    path.write_bytes(struct.pack("<4I", 4, 8 + len(hj), 4 + len(hj), len(hj)) + hj + blob)


def entry(path, exec_line, name):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f"[Desktop Entry]\nType=Application\nName={name}\nExec={exec_line}\n")


def build(root):
    home, sysd = root / "home", root / "sys"
    cfg, data, apps = home / ".config", home / ".local/share", sysd / "share/applications"
    for d in (cfg, data / "applications", sysd / "bin"):
        d.mkdir(parents=True)
    # A Chromium-style browser: its program next to icudtl.dat and resources.pak
    brave = sysd / "opt/fakebrowser/brave"
    elf(brave)
    (brave.parent / "icudtl.dat").write_bytes(b"")
    (brave.parent / "resources.pak").write_bytes(b"")
    entry(apps / "fakebrowser.desktop", f"{brave} %U", "Fake Browser")
    # ... and your autostart entry for it, which the desktop copy doesn't cover
    entry(cfg / "autostart/browser-tray.desktop", f"{brave} --no-startup-window", "Fake Browser (tray)")
    # An Electron app with cookie encryption, started by a launcher script that reads a flags file
    notes = sysd / "opt/notes/notes"
    elf(notes, fuse=True)
    (notes.parent / "resources").mkdir()
    asar(notes.parent / "resources/app.asar", {"package.json": json.dumps({"name": "notes", "productName": "Notes"}).encode()})
    launcher = sysd / "bin/notes"
    launcher.write_text('#!/bin/sh\nflags=$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/notes-flags.conf" 2>/dev/null)\n'
                        f'exec {notes} $flags "$@"\n')
    launcher.chmod(0o755)
    entry(apps / "notes.desktop", "notes %U", "Notes")
    # A VS Code-style app: product.json with a data folder; safeStorage in its code
    code = sysd / "opt/fakecode/fakecode"
    elf(code, fuse=False)
    appdir = code.parent / "resources/app"
    (appdir / "out").mkdir(parents=True)
    (appdir / "product.json").write_text(json.dumps({"dataFolderName": ".fakecode", "nameShort": "FakeCode"}))
    (appdir / "out/main.js").write_text("const k = safeStorage.encryptString(x);\n")
    entry(apps / "fakecode.desktop", f"{code} %F", "Fake Code")
    # An Electron app with no key: fuse off, no safeStorage
    plain = sysd / "opt/plain/plain"
    elf(plain, fuse=False)
    entry(apps / "plain.desktop", str(plain), "Plain")
    # update-desktop-database: logged, never the real one
    udd = sysd / "bin/update-desktop-database"
    udd.write_text(f'#!/bin/sh\necho "$@" >>"{root}/udd.log"\n')
    udd.chmod(0o755)
    env = {"HOME": str(home), "XDG_CONFIG_HOME": str(cfg), "XDG_DATA_HOME": str(data),
           "XDG_DATA_DIRS": str(sysd / "share"), "PATH": f"{sysd / 'bin'}:/usr/bin:/bin",
           "KEYRING_SWITCH_DESKTOP": "Hyprland", "XDG_RUNTIME_DIR": str(root / "run"),
           "DBUS_SESSION_BUS_ADDRESS": f"unix:path={root / 'run/no-bus'}", "LC_ALL": "C.UTF-8"}
    (root / "run").mkdir()
    return env, {"brave": brave, "notes": notes, "launcher": launcher, "code": code, "plain": plain}


def tree_hash(root):
    h = hashlib.sha256()
    for p in sorted(root.rglob("*")):
        h.update(str(p.relative_to(root)).encode())
        if p.is_file():
            h.update(p.read_bytes())
    return h.hexdigest()


def load(gi_dir):
    """keyring-switch.py as a module, with the stand-in gi"""
    sys.path.insert(0, str(gi_dir))
    spec = importlib.util.spec_from_file_location("keyring_switch", SWITCH)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    sys.path.remove(str(gi_dir))
    return mod


class FakeStores:
    """The stores, in memory: {store: [(attrs, value)]}"""

    def __init__(self, items, available=("gnome", "kwallet")):
        self.items, self.up = items, set(available)

    def available(self, store):
        return store in self.up

    def _match(self, store, attrs):
        return [(i, a, v) for i, (a, v) in enumerate(self.items.get(store, [])) if all(a.get(k) == x for k, x in attrs.items())]

    def search(self, store, attrs):
        return [f"/{store}/{i}" for i, *_ in self._match(store, attrs)], []

    def read(self, store, attrs):
        return [(f"/{store}/{i}", "label", a, v) for i, a, v in self._match(store, attrs)]


# ---------------------------------------------------------------- the tests

def test_discover_plan_write(ks, home):
    apps = {a.name: a for a in ks.discover() if a.kind != "python-keyring"}
    check(set(apps) == {"fakebrowser", "notes", "fakecode", "plain"}, "discover: the four apps", sorted(apps))
    b, n, c, p = (apps.get(k) for k in ("fakebrowser", "notes", "fakecode", "plain"))
    if not all((b, n, c, p)):
        return
    check(b.kind == "browser" and (b.secret_app, b.kwallet_name) == ("brave", "Brave") and not b.name_guessed,
          "browser: brave / Brave", (b.kind, b.secret_app, b.kwallet_name))
    check(b.route[0] == "desktop" and b.route[1] == home / ".local/share/applications/fakebrowser.desktop",
          "browser: a copy of its desktop entry", b.route)
    check(n.kind == "electron" and n.keys and n.why == "cookie encryption on", "electron: cookie encryption", (n.kind, n.why))
    check((n.secret_app, n.kwallet_name, n.name_guessed) == ("Notes", "Notes", False), "electron: key named after productName",
          (n.secret_app, n.kwallet_name, n.name_guessed))
    check(n.route[0] == "flags" and n.route[1] == home / ".config/notes-flags.conf", "electron: its launcher's flags file", n.route)
    check(b.bypass == [home / ".config/autostart/browser-tray.desktop"], "browser: your autostart entry found too", b.bypass)
    check(not n.bypass and not c.bypass, "no other entries to cover", (n.bypass, c.bypass))
    check(c.route == ("argv", home / ".fakecode/argv.json") and c.secret_app == "FakeCode" and c.why == "uses safeStorage",
          "VS Code-style: argv.json, nameShort, safeStorage", (c.route, c.secret_app, c.why))
    check(not p.keys, "no key: found, marked unused", p.why)
    check(all(ks.store_set(a) == ("gnome", False) for a in (b, n, c)), "nothing set yet: gnome-keyring by default (Hyprland)")
    check([a.name for a in ks.select(list(apps.values()), [], True)] == [a.name for a in apps.values() if a.keys],
          "--all: only the apps that keep a key")

    # ---- the plan
    kw = {"server": "Notes Keys", "user": "Notes Safe Storage", "type": "plaintext"}
    stores = FakeStores({"kwallet": [(kw, b"old-from-kwallet")]})
    actions, notes, go = ks.plan_key(stores, n, "kwallet", "gnome")
    check(go and [a[0] for a in actions] == ["put"] and actions[0][2] == {
        "application": "Notes", "xdg:schema": "chrome_libsecret_os_crypt_password_v2"} and actions[0][4] == b"old-from-kwallet",
        "plan: KWallet's key put into gnome-keyring under libsecret's name", actions)
    stores.items["gnome"] = [({"application": "Notes"}, b"another")]
    actions, notes, go = ks.plan_key(stores, n, "kwallet", "gnome")
    check(go and [a[0] for a in actions] == ["keep", "put"] and actions[0][3] == b"another",
          "plan: a different key already there is kept aside first", [a[0] for a in actions])
    stores.items["gnome"] = [({"application": "Notes"}, b"old-from-kwallet")]
    actions, notes, go = ks.plan_key(stores, n, "kwallet", "gnome")
    check(go and not actions and any("already the same key" in x for x in notes), "plan: the same key: nothing to write", notes)
    actions, notes, go = ks.plan_key(FakeStores({}), n, "kwallet", "gnome")
    check(go and not actions and any("nothing to carry over" in x for x in notes), "plan: no key anywhere: nothing written", notes)
    actions, notes, go = ks.plan_key(FakeStores({}, available=("gnome",)), n, "kwallet", "gnome")
    check(go and not actions and any("isn't running or installed" in x for x in notes), "plan: the old store is gone", notes)
    # Chromium's own KWallet key is what every Electron app on KWallet shares: a different one there holds it back
    chromium = types.SimpleNamespace(kind="browser", secret_app="chromium", kwallet_name="Chromium", name="chromium")
    shared = {"server": "Chromium Keys", "user": "Chromium Safe Storage", "type": "plaintext"}
    stores = FakeStores({"gnome": [({"application": "chromium"}, b"gk")], "kwallet": [(shared, b"electron-shared")]})
    actions, notes, go = ks.plan_key(stores, chromium, "gnome", "kwallet")
    check(not go and not actions, "plan: Chromium held back when KWallet's shared key differs", notes)
    actions, notes, go = ks.plan_key(FakeStores({}), n, "gnome", "gnome")
    check(go and not actions and not notes, "plan: already there: nothing")

    # ---- writing the routes
    flags = home / ".config/notes-flags.conf"
    flags.write_text("--enable-features=Foo\n# my comment\n--password-store=basic\n")
    argv = home / ".fakecode/argv.json"
    argv.parent.mkdir(parents=True)
    argv.write_text('{\n\t// mine\n\t"enable-crash-reporter": false\n}\n')
    for a in (b, n, c):
        ks.write_route(a, "gnome")
    first = {f: f.read_text() for f in (flags, argv, b.route[1], b.bypass[0])}
    check(ks.store_set(n) == ("gnome", True) and ks.store_set(b) == ("gnome", True) and ks.store_set(c) == ("gnome", True),
          "write: every app now names gnome-keyring")
    lines = flags.read_text().splitlines()
    check(lines[:2] == ["--enable-features=Foo", "# my comment"] and lines.count("--password-store=gnome-libsecret") == 1
          and not any("basic" in x for x in lines), "write: flags file: your lines kept, one --password-store", lines)
    text = argv.read_text()
    check("// mine" in text and '"enable-crash-reporter": false' in text and '"password-store": "gnome-libsecret"' in text,
          "write: argv.json: key added, comments and settings kept", text)
    copy = b.route[1].read_text()
    check("Exec=" + str(b.program) + " --password-store=gnome-libsecret %U" in copy and copy.startswith(ks.MARK),
          "write: desktop copy: the flag after the program, marked", copy)
    tray = b.bypass[0].read_text()
    check(f"Exec={b.program} --password-store=gnome-libsecret --no-startup-window" in tray,
          "write: the autostart entry gets it too", tray)
    for a in (b, n, c):
        ks.write_route(a, "gnome")
    check({f: f.read_text() for f in first} == first, "write: the same again: no change")
    for a in (b, n, c):
        ks.write_route(a, "kwallet")
    check(all(ks.store_set(a) == ("kwallet", True) for a in (b, n, c)), "write: and back to KWallet")
    check(flags.read_text().count("--password-store") == 1 and "--password-store=kwallet6" in flags.read_text(),
          "write: flags file: the old flag replaced", flags.read_text())
    check(b.route[1].read_text().count("--password-store") == 1 and ks.MARK in b.route[1].read_text(),
          "write: desktop copy: one flag, one mark")
    check(argv.read_text().count('"password-store"') == 1, "write: argv.json: one key", argv.read_text())


def run_cli(env, args, gi_dir=None):
    """A script run as a command; with gi_dir, the stand-in gi on its path"""
    if gi_dir:
        code = ("import runpy, sys; sys.path.insert(0, sys.argv[1]); script = sys.argv[2]; sys.argv = sys.argv[2:]; "
                "runpy.run_path(script, run_name='__main__')")
        cmd = [sys.executable, "-I", "-c", code, str(gi_dir)] + [str(a) for a in args]
    else:
        cmd = [sys.executable, "-I"] + [str(a) for a in args]
    return subprocess.run(cmd, env=env, capture_output=True, text=True, timeout=60)


def test_no_bus(env, root, gi_dir, label):
    home = Path(env["HOME"])
    before = tree_hash(home)
    for args, what in (([SWITCH, "status"], "keyring-switch status"),
                       ([SWITCH, "set", "gnome", "--all", "--dry-run"], "keyring-switch set --all --dry-run"),
                       ([SWITCH, "set", "kwallet", "notes"], "keyring-switch set kwallet notes"),
                       ([KW2GK, "--dry-run"], "kwallet-to-keyring --dry-run"),
                       ([KW2GK, "--write"], "kwallet-to-keyring --write")):
        r = run_cli(env, args, gi_dir)
        check(r.returncode == 1 and "no session bus" in r.stderr and "Traceback" not in r.stderr,
              f"{label}: {what}: a message, exit 1", f"exit {r.returncode}: {r.stderr.strip()[-400:]}")
    check(tree_hash(home) == before, f"{label}: no file changed")
    check(not (root / "udd.log").exists(), f"{label}: update-desktop-database never ran")


def main():
    root = Path(tempfile.mkdtemp(prefix="keyring-switch-test-"))
    try:
        env, _ = build(root)
        gi_dir = fake_gi(root)
        # 4 first, on the untouched HOME
        real = subprocess.run([sys.executable, "-I", "-c", "import gi; gi.require_version('Gio', '2.0')"],
                              capture_output=True).returncode == 0
        if real:
            test_no_bus(env, root, None, "PyGObject")
        elif os.environ.get("CI") == "true":
            check(False, "PyGObject is installed (CI=true: the real gi is tested too)", "import gi failed")
        else:
            print("skip: PyGObject is not installed (the stand-in gi is used alone)")
        test_no_bus(env, root, gi_dir, "stand-in gi")
        # 1-3 in this process, with the stand-in gi and the fake HOME
        saved = dict(os.environ)
        os.environ.update(env)
        try:
            ks = load(gi_dir)
            test_discover_plan_write(ks, Path(env["HOME"]))
        finally:
            os.environ.clear()
            os.environ.update(saved)
    finally:
        shutil.rmtree(root, ignore_errors=True)
    if fails:
        print(f"keyring-switch tests: {fails} FAILED")
        sys.exit(1)
    print("keyring-switch tests: OK")


main()

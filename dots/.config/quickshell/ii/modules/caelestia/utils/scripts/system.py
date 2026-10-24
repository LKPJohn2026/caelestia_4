#!/usr/bin/env python3
"""caelestia4: data for Nexus > Updates and Nexus > Plugins (shell components). Prints JSON; never changes anything.

Usage:
  system.py updates      pending Arch repo updates (checkupdates), AUR updates (yay -Qua) and new commits for the
                         caelestia_4 clone (git fetch). Also saved to $XDG_STATE_HOME/caelestia4/updates.json
  system.py cached       the last `updates` result (or {} before the first check)
  system.py components   Quickshell, the Caelestia QML plugin, Qt and Hyprland plugins: versions, the Qt each
                         was built with, and whether it needs a rebuild for the installed Qt
"""
import datetime, json, os, re, shutil, subprocess, sys

HOME = os.path.expanduser("~")
CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config")
STATE = os.environ.get("XDG_STATE_HOME") or os.path.join(HOME, ".local/state")
CACHE_FILE = os.path.join(STATE, "caelestia4/updates.json")
REPO_FILE = os.path.join(CONFIG, "caelestia4/repo")  # written by tools/install-main.sh
PLUGIN_DIR = os.path.join(HOME, ".local/lib/qt6/qml/Caelestia")
PLUGIN_STAMP = os.path.join(PLUGIN_DIR, "caelestia4-build.json")  # written by tools/build-caelestia-plugin.sh


def run(cmd, timeout=60, cwd=None):
    """(exit code, stdout); 127 when the program is missing, 124 on timeout"""
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, cwd=cwd)
        return p.returncode, p.stdout
    except FileNotFoundError:
        return 127, ""
    except subprocess.TimeoutExpired:
        return 124, ""


def parse_updates(text):
    """`name old -> new` lines (checkupdates, yay -Qua)"""
    out = []
    for line in text.splitlines():
        m = re.match(r"^(\S+)\s+(\S+)\s+->\s+(\S+)", line.strip())
        if m:
            out.append({"name": m.group(1), "from": m.group(2), "to": m.group(3)})
    return out


def repo_updates():
    if not shutil.which("checkupdates"):
        return {"available": False, "packages": [], "error": "checkupdates is not installed (pacman-contrib)"}
    code, out = run(["checkupdates", "--nocolor"], timeout=120)
    if code in (0, 2):  # 2 = nothing to update
        return {"available": True, "packages": parse_updates(out), "error": ""}
    return {"available": True, "packages": [], "error": "checkupdates failed (offline?)"}


def aur_updates():
    helper = next((h for h in ("yay", "paru") if shutil.which(h)), None)
    if not helper:
        return {"available": False, "helper": "", "packages": [], "error": ""}
    code, out = run([helper, "-Qua"], timeout=120)
    # exit 1 with no output = nothing to update
    return {"available": True, "helper": helper, "packages": parse_updates(out),
            "error": "" if code in (0, 1) else f"{helper} -Qua failed (offline?)"}


def repo_path():
    try:
        with open(REPO_FILE) as f:
            path = f.read().strip()
        return path if os.path.isdir(os.path.join(path, ".git")) else ""
    except OSError:
        return ""


def caelestia4_updates():
    path = repo_path()
    if not path:
        return {"path": "", "error": "clone not found (run tools/install-main.sh once)"}
    git = lambda *a, timeout=30: run(["git", "-C", path, *a], timeout=timeout)
    fetch_code, _ = git("fetch", "--quiet", timeout=60)
    _, branch = git("rev-parse", "--abbrev-ref", "HEAD")
    code, upstream = git("rev-parse", "--abbrev-ref", "@{u}")
    if code != 0:
        return {"path": path, "branch": branch.strip(), "error": "the branch has no upstream"}
    _, behind = git("rev-list", "--count", "HEAD..@{u}")
    _, ahead = git("rev-list", "--count", "@{u}..HEAD")
    _, dirty = git("status", "--porcelain")
    _, log = git("log", "--format=%h%x09%cI%x09%s", "-n", "30", "HEAD..@{u}")
    commits = [dict(zip(("hash", "date", "subject"), l.split("\t", 2))) for l in log.splitlines() if l.count("\t") >= 2]
    return {
        "path": path, "branch": branch.strip(), "upstream": upstream.strip(),
        "behind": int(behind.strip() or 0), "ahead": int(ahead.strip() or 0), "dirty": bool(dirty.strip()),
        "commits": commits, "error": "" if fetch_code == 0 else "git fetch failed (offline?): showing the last fetch",
    }


def qt_installed():
    code, out = run(["pacman", "-Q", "qt6-base"])
    return out.split()[1].split("-")[0] if code == 0 and len(out.split()) > 1 else ""


def needs_rebuild(built, installed):
    """Whether a component built against Qt `built` (e.g. "6.12.0") must be rebuilt to run on the installed Qt
    `installed`. Quickshell and the Caelestia plugin use Qt's private API, which is only stable within one Qt minor
    release. Return True / False, or None when it can't be told (a version is unknown)."""
    # TODO(human)
    return None


def quickshell_info(qt):
    _, out = run(["qs", "--version"])
    m = re.search(r"Quickshell (\S+) \(revision (\w+)", out)
    built = ""
    exe = shutil.which("quickshell") or shutil.which("qs")
    if exe:
        with open(os.path.realpath(exe), "rb") as f:
            hit = re.search(rb"\x00(6\.\d+\.\d+)\x00", f.read())  # QT_VERSION_STR compiled into the binary
        built = hit.group(1).decode() if hit else ""
    code, pkg = run(["pacman", "-Qqo", os.path.realpath(exe)]) if exe else (1, "")
    return {
        "name": "Quickshell", "version": m.group(1) if m else out.strip(), "revision": (m.group(2)[:9] if m else ""),
        "package": pkg.strip() if code == 0 else "", "builtQt": built, "needsRebuild": needs_rebuild(built, qt),
    }


def plugin_info(qt):
    stamp = {}
    try:
        with open(PLUGIN_STAMP) as f:
            stamp = json.load(f)
    except (OSError, ValueError):
        pass
    modules = sorted(d for d in os.listdir(PLUGIN_DIR) if os.path.isdir(os.path.join(PLUGIN_DIR, d)) and d != "lib") \
        if os.path.isdir(PLUGIN_DIR) else []
    core = os.path.join(PLUGIN_DIR, "lib/libcaelestia-core.so")
    built_at = stamp.get("built") or (datetime.datetime.fromtimestamp(os.path.getmtime(core)).isoformat(timespec="seconds")
                                      if os.path.exists(core) else "")
    return {
        "name": "Caelestia plugin", "version": stamp.get("version", ""), "revision": stamp.get("revision", ""),
        "builtQt": stamp.get("qt", ""), "built": built_at, "installed": bool(modules), "modules": modules,
        "needsRebuild": needs_rebuild(stamp.get("qt", ""), qt),
    }


def hyprland_plugins():
    code, out = run(["hyprctl", "plugin", "list", "-j"])
    try:
        data = json.loads(out) if code == 0 else []
        return [{"name": p.get("name", ""), "author": p.get("author", ""), "version": p.get("version", ""),
                 "description": p.get("description", "")} for p in data if isinstance(p, dict)]
    except ValueError:
        return []


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "updates":
        data = {"checked": datetime.datetime.now().isoformat(timespec="seconds"),
                "repo": repo_updates(), "aur": aur_updates(), "caelestia4": caelestia4_updates()}
        os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
        with open(CACHE_FILE + ".tmp", "w") as f:
            json.dump(data, f)
        os.replace(CACHE_FILE + ".tmp", CACHE_FILE)
        print(json.dumps(data))
    elif cmd == "cached":
        try:
            print(open(CACHE_FILE).read().strip() or "{}")
        except OSError:
            print("{}")
    elif cmd == "components":
        qt = qt_installed()
        print(json.dumps({"qtInstalled": qt, "repo": repo_path(),
                          "components": [quickshell_info(qt), plugin_info(qt)], "hyprlandPlugins": hyprland_plugins()}))
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()

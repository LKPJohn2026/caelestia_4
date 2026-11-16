#!/usr/bin/env python3
"""caelestia4: the keyboard shortcuts behind Nexus > Hyprland > Keyboard shortcuts.

The shortcuts come from ~/.config/hypr/hyprland/keybinds.lua (the defaults) and custom/keybinds.lua (the user's), read
by nexus-keybinds-dump.lua. Nexus never edits those two files: its changes go to ~/.config/hypr/custom/nexus-keybinds.lua,
which hyprland.lua loads before keybinds.lua. That file wraps hl.bind, so a changed shortcut keeps its action (Lua
functions included) and only its keys change; a turned-off one is skipped; added ones are bound at its end. The file
also defines the empty "nexus-capture" submap that Nexus enters while it waits for the new keys (Escape leaves it).

A shortcut is every bind on one key combination (in one submap): changing it moves them all. A digit's key-code twin
(Super + code:10 beside Super + 1, so it works on any layout) is the same keys: it is folded into the digit's shortcut
(twinId) and goes off whenever that one is changed or off.

Usage: nexus-keybinds.py [--hypr DIR] [--reload] COMMAND [ARGS]
  list                  the shortcuts as JSON (with the state applied; "conflict": the id of another working one on
                        the same keys)
  state                 the saved changes as JSON
  set-state JSON        replaces the saved changes (Nexus's undo)
  remap ID KEYS         gives shortcut ID new keys ("SUPER + SHIFT + W")
  disable ID | enable ID | reset ID | reset-all
  add KEYS COMMAND TITLE   a new shortcut that runs COMMAND;  remove ID  removes an added one
  ensure                writes the file when it is missing (the capture submap needs it)
remap, add, enable and reset take --replace ID2: the shortcut that had those keys is turned off (an added one removed)
first. A shortcut made outside the two files can't be replaced: the command fails (exit 3).
--reload runs `hyprctl reload` after a write (only when the file is loaded by hyprland.lua).
"""
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(os.path.expanduser("~"), ".config")
SOURCE_MARK = "custom.nexus-keybinds"

MOD_ALIASES = {"SUPER": "SUPER", "WIN": "SUPER", "LOGO": "SUPER", "MOD4": "SUPER", "META": "SUPER",
               "CTRL": "CTRL", "CONTROL": "CTRL", "ALT": "ALT", "MOD1": "ALT", "SHIFT": "SHIFT",
               "CAPS": "CAPS", "MOD2": "MOD2", "MOD3": "MOD3", "MOD5": "MOD5"}
MOD_ORDER = ["SUPER", "CTRL", "ALT", "SHIFT", "CAPS", "MOD2", "MOD3", "MOD5"]
MODMASK = {"SHIFT": 1, "CAPS": 2, "CTRL": 4, "ALT": 8, "MOD2": 16, "MOD3": 32, "SUPER": 64, "MOD5": 128}


def split_keys(keys):
    """("SUPER + shift + Q") -> (["SUPER", "SHIFT"] in MOD_ORDER, "Q")"""
    parts = [p.strip() for p in re.split(r"\s*\+\s*", keys.strip()) if p.strip()]
    mods, key = set(), ""
    for i, p in enumerate(parts):
        up = p.upper()
        if up in MOD_ALIASES and i < len(parts) - 1:
            mods.add(MOD_ALIASES[up])
        else:
            key = p
    return [m for m in MOD_ORDER if m in mods], key


def norm(keys):
    """The comparable form of a key combination: "SUPER+SHIFT+q" (the Lua hook computes the same)"""
    mods, key = split_keys(keys)
    return "+".join(mods + [key.lower()])


def canonical(keys):
    """The form written to hl.bind: "SUPER + SHIFT + Q" """
    mods, key = split_keys(keys)
    if len(key) == 1:
        key = key.upper()
    return " + ".join(mods + [key])


def sid(submap, keys):
    return f"{submap}|{norm(keys)}"


def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "") + '"'


class Paths:
    def __init__(self, hypr):
        self.hypr = hypr
        self.file = os.path.join(hypr, "custom", "nexus-keybinds.lua")
        self.main = os.path.join(hypr, "hyprland.lua")


def empty_state():
    return {"version": 1, "remap": {}, "disabled": [], "added": []}


def read_state(p):
    try:
        with open(p.file, encoding="utf-8") as f:
            for line in f:
                if line.startswith("-- nexus-state: "):
                    st = json.loads(line[len("-- nexus-state: "):])
                    out = empty_state()
                    out["remap"] = {str(k): str(v) for k, v in (st.get("remap") or {}).items()}
                    out["disabled"] = [str(x) for x in st.get("disabled") or []]
                    out["added"] = [a for a in st.get("added") or [] if isinstance(a, dict) and a.get("keys")]
                    return out
    except (OSError, ValueError):
        pass
    return empty_state()


HOOK = r'''
local MODS = { SUPER = "SUPER", WIN = "SUPER", LOGO = "SUPER", MOD4 = "SUPER", META = "SUPER", CTRL = "CTRL",
    CONTROL = "CTRL", ALT = "ALT", MOD1 = "ALT", SHIFT = "SHIFT", CAPS = "CAPS", MOD2 = "MOD2", MOD3 = "MOD3", MOD5 = "MOD5" }
local ORDER = { "SUPER", "CTRL", "ALT", "SHIFT", "CAPS", "MOD2", "MOD3", "MOD5" }

-- "SUPER + shift + Q" -> "SUPER+SHIFT+q", as nexus-keybinds.py's norm()
local function norm(keys)
    local parts = {}
    for raw in tostring(keys):gmatch("[^+]+") do
        local p = raw:match("^%s*(.-)%s*$")
        if p ~= "" then parts[#parts + 1] = p end
    end
    local mods, key = {}, ""
    for i, p in ipairs(parts) do
        local m = MODS[p:upper()]
        if m and i < #parts then mods[m] = true else key = p end
    end
    local out = {}
    for _, m in ipairs(ORDER) do
        if mods[m] then out[#out + 1] = m end
    end
    out[#out + 1] = key:lower()
    return table.concat(out, "+")
end

local bind = hl.bind
local define = hl.define_submap
local submap = ""
local off = setmetatable({}, { __index = function() return function() end end })

hl.define_submap = function(name, a, b)
    local fn = type(a) == "function" and a or b
    if type(fn) ~= "function" then return define(name, a, b) end
    local wrapped = function(...)
        local prev = submap
        submap = tostring(name)
        local r = fn(...)
        submap = prev
        return r
    end
    if type(a) == "function" then return define(name, wrapped) end
    return define(name, a, wrapped)
end

hl.bind = function(keys, dsp, opts)
    local id = submap .. "|" .. norm(keys)
    if disabled[id] then return off end
    return bind(remap[id] or keys, dsp, opts)
end

-- While Nexus waits for the new keys of a shortcut: no shortcut works, Escape leaves
define("nexus-capture", function()
    bind("Escape", hl.dsp.submap("reset"))
end)
'''


def write_state(p, st):
    lines = [
        "-- caelestia4: written by Nexus (Hyprland > Keyboard shortcuts). Change shortcuts there: this file is rewritten",
        "-- each time. hyprland.lua loads it before hyprland/keybinds.lua, so it changes or skips the binds that file and",
        "-- custom/keybinds.lua make. Delete it to get every shortcut back as it was.",
        "-- nexus-state: " + json.dumps(st, ensure_ascii=True, separators=(",", ":")),
        "",
        "local remap = {",
    ]
    for k, v in sorted(st["remap"].items()):
        lines.append(f"    [{lua_str(k)}] = {lua_str(canonical(v))},")
    lines.append("}")
    lines.append("local disabled = {")
    for k in sorted(set(st["disabled"])):
        lines.append(f"    [{lua_str(k)}] = true,")
    lines.append("}")
    lines.append(HOOK.rstrip())
    if st["added"]:
        lines.append("")
        lines.append("-- Added in Nexus")
        lines.append("local run = function(cmd) return hl.dsp.exec_cmd(type(app) == \"function\" and app(cmd) or cmd) end")
        for a in st["added"]:
            lines.append(f"bind({lua_str(canonical(a['keys']))}, run({lua_str(a.get('command', ''))}), "
                         f"{{ description = {lua_str('Added: ' + a.get('title', ''))} }})")
    os.makedirs(os.path.dirname(p.file), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(p.file), prefix=".nexus-keybinds.")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    os.replace(tmp, p.file)


def sourced(p):
    try:
        with open(p.main, encoding="utf-8") as f:
            return any(SOURCE_MARK in line and not line.lstrip().startswith("--") for line in f)
    except OSError:
        return False


def dump(p):
    try:
        r = subprocess.run(["lua", os.path.join(HERE, "nexus-keybinds-dump.lua"), p.hypr], capture_output=True,
                           text=True, timeout=10)
        d = json.loads(r.stdout or "{}")
    except (OSError, ValueError, subprocess.TimeoutExpired) as e:
        return [], [str(e)]
    return d.get("binds") or [], d.get("errors") or []


def live_binds():
    """`hyprctl binds -j` (read only), for shortcuts made somewhere else (plugins, other config files)"""
    if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        return []
    try:
        r = subprocess.run(["hyprctl", "binds", "-j"], capture_output=True, text=True, timeout=3)
        return json.loads(r.stdout or "[]")
    except (OSError, ValueError, subprocess.TimeoutExpired):
        return []


CATEGORY_HEADER = re.compile(r"^\s*--##!\s*(.*\S)?")
CATEGORY_END = re.compile(r"^\s*--#!\s*$")
# Number-row and keypad key codes (keybinds.lua binds both beside the digits): code -> digit
DIGIT_CODES = {**{10 + i: str((i + 1) % 10) for i in range(10)},
               **dict(zip([87, 88, 89, 83, 84, 85, 79, 80, 81, 90], "1234567890"))}
MOD_KEYS = {"super_l": "SUPER", "super_r": "SUPER", "alt_l": "ALT", "alt_r": "ALT", "control_l": "CTRL",
            "control_r": "CTRL", "shift_l": "SHIFT", "shift_r": "SHIFT"}


def file_categories(path):
    """{line: category} from the "--##! Name" headers above each line ("--#!" ends one)"""
    cats, cur = {}, ""
    try:
        with open(path, encoding="utf-8") as f:
            for n, line in enumerate(f, 1):
                m = CATEGORY_HEADER.match(line)
                if m:
                    cur = (m.group(1) or "").strip()
                elif CATEGORY_END.match(line):
                    cur = ""
                cats[n] = cur
    except OSError:
        pass
    return cats


def hidden_line(path, line, cache):
    if path not in cache:
        try:
            with open(path, encoding="utf-8") as f:
                cache[path] = f.read().split("\n")
        except OSError:
            cache[path] = []
    lines = cache[path]
    return 0 < line <= len(lines) and "[hidden]" in lines[line - 1]


def build(p):
    st = read_state(p)
    raw, errors = dump(p)
    disabled = set(st["disabled"])
    cats_cache, text_cache = {}, {}
    groups, order = {}, []
    for b in raw:
        bid = sid(b.get("submap", ""), b["keys"])
        g = groups.get(bid)
        if not g:
            g = groups[bid] = {"id": bid, "submap": b.get("submap", ""), "keys": canonical(b["keys"]),
                               "source": b.get("source", "default"), "binds": []}
            order.append(bid)
        g["binds"].append(b)
    out = []
    for bid in order:
        g = groups[bid]
        binds = g.pop("binds")
        desc = next((b["opts"].get("description") or b["opts"].get("desc") for b in binds
                     if isinstance(b["opts"], dict) and (b["opts"].get("description") or b["opts"].get("desc"))), "")
        first = binds[0]
        path = first.get("file", "")
        if path not in cats_cache:
            cats_cache[path] = file_categories(path)
        category, title = "", desc
        if ":" in desc:
            category, title = desc.split(":", 1)
            category, title = category.strip(), title.strip()
        if not category:
            category = cats_cache[path].get(first.get("line", 0), "")
        opts = [b["opts"] if isinstance(b["opts"], dict) else {} for b in binds]
        g.update({
            "title": title,
            "category": category,
            "action": first.get("action", {}),
            "mouse": any(o.get("mouse") for o in opts) or "mouse" in g["keys"].lower(),
            "locked": any(o.get("locked") for o in opts),
            "release": all(o.get("release") for o in opts),
            "repeating": any(o.get("repeating") for o in opts),
            "internal": all(o.get("ignore_mods") or o.get("transparent") for o in opts),
            # caelestia4: works in every submap (the virtual machine toggle)
            "universal": any(o.get("submap_universal") for o in opts),
            "hidden": all(hidden_line(path, b.get("line", 0), text_cache) for b in binds),
            "count": len(binds),
            "status": "disabled" if bid in disabled else ("changed" if bid in st["remap"] else "default"),
            "currentKeys": canonical(st["remap"].get(bid, g["keys"])),
        })
        out.append(g)
    link_untitled(out)
    twins = fold_twins(out)
    for i, a in enumerate(st["added"]):
        keys = canonical(a["keys"])
        out.append({"id": "added|" + norm(keys), "submap": "", "keys": keys, "currentKeys": keys, "source": "added",
                    "title": a.get("title", ""), "category": "", "action": {"name": "exec_cmd", "args": {"1": a.get("command", "")}},
                    "mouse": False, "locked": False, "release": False, "repeating": False, "internal": False,
                    "hidden": False, "count": 1, "status": "added", "command": a.get("command", "")})
    # shortcuts made outside the two files (only seen while Hyprland runs)
    # (default and changed keys both count: Hyprland may not have reloaded since the last change)
    known = {(s["submap"], norm(k)) for s in out for k in (s["keys"], s["currentKeys"])}
    known |= {(t["submap"], norm(t["keys"])) for t in twins}
    for b in live_binds():
        mods = [m for m in MOD_ORDER if b.get("modmask", 0) & MODMASK[m]]
        key = b.get("key") or (f"code:{b['keycode']}" if b.get("keycode") else "")
        if not key:
            continue
        keys = " + ".join(mods + [key])
        k = (b.get("submap", ""), norm(keys))
        # Hyprland adds a modifier key's own modifier ("ALT_L" shows as ALT + ALT_L)
        own = MOD_KEYS.get(key.lower())
        bare = (k[0], norm(" + ".join([m for m in mods if m != own] + [key]))) if own else k
        if k in known or bare in known or b.get("submap") == "nexus-capture":
            continue
        known.add(k)
        d = b.get("description") or ""
        out.append({"id": "other|" + k[0] + "|" + k[1], "submap": k[0], "keys": canonical(keys),
                    "currentKeys": canonical(keys), "source": "other", "title": d.split(":", 1)[-1].strip(),
                    "category": "", "action": {"name": "unknown"}, "mouse": bool(b.get("mouse")),
                    "locked": bool(b.get("locked")), "release": bool(b.get("release")), "repeating": bool(b.get("repeat")),
                    "internal": False, "hidden": False, "count": 1, "status": "other"})
    # turned off here but made outside the two files: still listed, so it can be turned back on
    listed = {s["id"] for s in out} | {t["id"] for t in twins}
    for bid in st["disabled"]:
        if bid not in listed and "|" in bid:
            submap, combo = bid.split("|", 1)
            parts = combo.split("+")
            keys = canonical(" + ".join(parts[:-1] + [parts[-1]]))
            out.append({"id": bid, "submap": submap, "keys": keys, "currentKeys": keys, "source": "other", "title": "",
                        "category": "", "action": {"name": "unknown"}, "mouse": "mouse" in keys.lower(), "locked": False,
                        "release": False, "repeating": False, "internal": False, "hidden": False, "count": 1,
                        "status": "disabled"})
    mark_conflicts(out)
    return {"sourced": sourced(p), "fileExists": os.path.exists(p.file), "file": p.file, "shortcuts": out,
            "errors": errors}


def action_key(a):
    """Two binds do the same when this matches (Lua functions never do)"""
    if not a or a.get("name") in ("function", "unknown"):
        return None
    return json.dumps(a, sort_keys=True)


def link_untitled(out):
    """An untitled shortcut that does what a titled one does (Super+B as Super+A), or is its keypad or key-code twin
    (Super + code:10 as Super + 1), gets that one's title and category: sameAs (its id) and variant say so"""
    titled = [s for s in out if s["title"]]
    by_action, by_keys = {}, {}
    for s in titled:
        k = action_key(s["action"])
        if k:
            by_action.setdefault((s["submap"], k), s)
        by_keys.setdefault(s["id"], s)
    cats = {s["category"] for s in titled if s["category"]}
    for s in out:
        # a "--##! Apps" header and "App: ..." descriptions are one category
        if s["category"] not in cats and s["category"].endswith("s") and s["category"][:-1] in cats:
            s["category"] = s["category"][:-1]
        if s["title"]:
            continue
        mods, key = split_keys(s["keys"])
        twin, variant = None, ""
        m = re.fullmatch(r"code:(\d+)", key)
        if m and int(m.group(1)) in DIGIT_CODES:
            twin = by_keys.get(s["submap"] + "|" + "+".join(mods + [DIGIT_CODES[int(m.group(1))]]))
            variant = "keypad" if int(m.group(1)) >= 79 else "keycode"
        if not twin:
            twin = by_action.get((s["submap"], action_key(s["action"]) or ""))
            variant = "also"
        if twin:
            s["sameAs"], s["variant"], s["title"] = twin["id"], variant, twin["title"]
            s["category"] = twin["category"] or s["category"]
        if not s["category"]:
            name = s["action"].get("name", "")
            arg = str((s["action"].get("args") or {}).get("1", ""))
            if name == "global":
                s["category"] = "Shell"
            elif key.startswith("XF86Audio"):
                s["category"] = "Media"
            elif key.startswith("XF86MonBrightness"):
                s["category"] = "Screen"


def fold_twins(out):
    """Takes each digit's key-code twin out of the list into its digit's shortcut (twinId, twinKeys), as both are the
    same keys to the user. Returns the twins taken out"""
    by_id = {s["id"]: s for s in out}
    twins = [s for s in out if s.get("variant") == "keycode" and s.get("sameAs") in by_id]
    for t in twins:
        main = by_id[t["sameAs"]]
        main["twinId"], main["twinKeys"] = t["id"], t["keys"]
        main["count"] += t["count"]
        out.remove(t)
    return twins


def mark_conflicts(out):
    """"conflict": another working shortcut on the same keys, in the same submap or in every submap (universal)"""
    on = [s for s in out if s["status"] != "disabled" and not s["internal"]]
    for s in on:
        n = norm(s["currentKeys"])
        for o in on:
            if o is not s and norm(o["currentKeys"]) == n and (o["submap"] == s["submap"] or o.get("universal")
                                                                 or s.get("universal")):
                s["conflict"] = o["id"]
                break


def twin_of(p, bid):
    """The key-code twin id of shortcut BID, or None"""
    _, key = split_keys(bid.split("|", 1)[-1].replace("+", " + "))
    if not re.fullmatch(r"\d", key):
        return None
    return next((s.get("twinId") for s in build(p)["shortcuts"] if s["id"] == bid), None)


def set_off(st, ids, off):
    for x in ids:
        if not x:
            continue
        if off and x not in st["disabled"]:
            st["disabled"].append(x)
        elif not off:
            st["disabled"] = [y for y in st["disabled"] if y != x]


def reload_hypr(p):
    if sourced(p) and os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        subprocess.run(["hyprctl", "reload"], capture_output=True, timeout=5)


def main(argv):
    hypr, do_reload = os.path.join(CONFIG, "hypr"), False
    args = []
    i = 0
    while i < len(argv):
        if argv[i] == "--hypr":
            hypr = argv[i + 1]
            i += 2
        elif argv[i] == "--reload":
            do_reload = True
            i += 1
        else:
            args.append(argv[i])
            i += 1
    if not args:
        print(__doc__, file=sys.stderr)
        return 2
    p = Paths(hypr)
    cmd, rest = args[0], args[1:]
    if cmd == "list":
        print(json.dumps(build(p), ensure_ascii=False))
        return 0
    if cmd == "state":
        print(json.dumps(read_state(p)))
        return 0
    st = read_state(p)
    # --replace ID: the shortcut that had the new keys goes off first (an added one is removed)
    if "--replace" in rest:
        i = rest.index("--replace")
        other = rest[i + 1]
        rest = rest[:i] + rest[i + 2:]
        # caelestia4: a bind made outside the two files (a plugin, hyprctl keyword) can't be skipped by the hook
        if other.startswith("other|"):
            print("can't replace a shortcut made outside Nexus", file=sys.stderr)
            return 3
        if other.startswith("added|"):
            st["added"] = [a for a in st["added"] if "added|" + norm(a["keys"]) != other]
        else:
            set_off(st, [other, twin_of(p, other)], True)
    if cmd == "set-state":
        new = json.loads(rest[0])
        st = empty_state()
        st["remap"] = {str(k): str(v) for k, v in (new.get("remap") or {}).items()}
        st["disabled"] = [str(x) for x in new.get("disabled") or []]
        st["added"] = [a for a in new.get("added") or [] if isinstance(a, dict) and a.get("keys")]
    elif cmd == "remap":
        bid, keys = rest[0], rest[1]
        if bid.startswith("added|"):
            for a in st["added"]:
                if "added|" + norm(a["keys"]) == bid:
                    a["keys"] = canonical(keys)
        elif norm(keys) == bid.split("|", 1)[1]:
            st["remap"].pop(bid, None)
            set_off(st, [bid, twin_of(p, bid)], False)
        else:
            st["remap"][bid] = canonical(keys)
            set_off(st, [bid], False)
            # the twin would still do it on the old keys
            set_off(st, [twin_of(p, bid)], True)
    elif cmd == "disable":
        set_off(st, [rest[0], twin_of(p, rest[0])], True)
    elif cmd == "enable":
        set_off(st, [rest[0]] + ([] if rest[0] in st["remap"] else [twin_of(p, rest[0])]), False)
    elif cmd == "reset":
        st["remap"].pop(rest[0], None)
        set_off(st, [rest[0], twin_of(p, rest[0])], False)
    elif cmd == "reset-all":
        st = empty_state()
    elif cmd == "add":
        keys, command, title = rest[0], rest[1], rest[2] if len(rest) > 2 else ""
        st["added"] = [a for a in st["added"] if norm(a["keys"]) != norm(keys)]
        st["added"].append({"keys": canonical(keys), "command": command, "title": title})
    elif cmd == "remove":
        st["added"] = [a for a in st["added"] if "added|" + norm(a["keys"]) != rest[0]]
    elif cmd == "ensure":
        if os.path.exists(p.file):
            return 0
    else:
        print(__doc__, file=sys.stderr)
        return 2
    write_state(p, st)
    if do_reload:
        reload_hypr(p)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

#!/usr/bin/env python3
"""caelestia4: save the monitor setup (after the settings app's "Keep these settings?") to ~/.config/hypr/monitors.lua.

The screens in use get a rule from `hyprctl monitors all -j`, matched by description (make, model, serial) since a
connector name can change between boots. A description that is the start of another screen's goes by connector name:
Hyprland matches desc: by prefix and a later rule wins, so both screens would land in one place.
The file's other rules stay: a screen that isn't connected now, or one switched off. A rule is never written to switch a
screen off, as this may only be for the moment and the screen may be the only one at the next start. Fields this doesn't
set (vrr, bitdepth, cm...) stay in the rule of their screen. Anything else in the file is in monitors.lua.bak.
"""
import json
import os
import re
import shutil
import subprocess
import sys

OURS = {"output", "mode", "position", "scale", "transform", "mirror", "disabled"}
CALL = re.compile(r"hl\.monitor\s*\(")
FIELD = re.compile(r"\s*([A-Za-z_]\w*)\s*=\s*(.*\S)\s*", re.S)
STRING = re.compile(r'\s*"((?:[^"\\]|\\.)*)"\s*', re.S)


def skip(text, i):
    """The end of the comment or string at i, or i when there is neither"""
    if text.startswith("--", i):
        long = re.match(r"--\[(=*)\[", text[i:])
        if long:
            end = text.find("]" + long.group(1) + "]", i)
            return len(text) if end < 0 else end + len(long.group(1)) + 2
        end = text.find("\n", i)
        return len(text) if end < 0 else end
    if text[i] in "\"'":
        j = i + 1
        while j < len(text) and text[j] != text[i]:
            j += 2 if text[j] == "\\" else 1
        return min(j + 1, len(text))
    long = re.match(r"\[(=*)\[", text[i:])
    if long:
        end = text.find("]" + long.group(1) + "]", i)
        return len(text) if end < 0 else end + len(long.group(1)) + 2
    return i


def rules(text):
    """Each hl.monitor({...}) that is code, not a comment or inside a string: (its text with the comment line above, its fields)"""
    found, i = [], 0
    while i < len(text):
        after = skip(text, i)
        if after != i:
            i = after
            continue
        call = CALL.match(text, i)
        if not call or (i and (text[i - 1].isalnum() or text[i - 1] in "_.")):
            i += 1
            continue
        j, depth, fields, part = call.end(), 1, [], ""
        while j < len(text) and depth:
            after = skip(text, j)
            if after != j:
                if not text.startswith("--", j):
                    part += text[j:after]
                j = after
                continue
            char = text[j]
            if char in "({[":
                depth += 1
            elif char in ")}]":
                depth -= 1
            if depth >= 2 and not (depth == 2 and char == "{"):
                if depth == 2 and char in ",;":
                    fields.append(part)
                    part = ""
                else:
                    part += char
            elif depth == 2 and char == "}":
                part += char
            elif depth == 1 and char == "}":
                fields.append(part)
                part = ""
            j += 1
        if depth:
            break # never closed: not something to copy
        start = text.rfind("\n", 0, i) + 1
        above = text.rfind("\n", 0, max(start - 1, 0)) + 1
        comment = text[above:start] if start and text[above:start].lstrip().startswith("--") and "hl.monitor" not in text[above:start] else ""
        parsed = {}
        for field in fields:
            match = FIELD.fullmatch(field)
            if match:
                parsed[match.group(1)] = match.group(2)
        found.append((comment + text[i:j], parsed))
        i = j
    return found


def selector_of(fields):
    literal = STRING.fullmatch(fields.get("output", ""))
    return re.sub(r"\\(.)", r"\1", literal.group(1)) if literal else None


def matches(selector, monitor):
    if selector is None:
        return False
    if selector.startswith("desc:"):
        return len(selector) > 5 and monitor["description"].startswith(selector[5:])
    return selector == monitor["name"]


def lua(text):
    return text.replace("\\", "\\\\").replace('"', '\\"')


def main():
    query = subprocess.run(["hyprctl", "monitors", "all", "-j"], capture_output=True, check=True, encoding="utf-8", errors="surrogateescape")
    known = json.loads(query.stdout)
    active = [m for m in known if not m.get("disabled")]
    if not active:
        sys.exit("monitors-save: Hyprland lists no screen in use, nothing saved")

    out = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"), "hypr/monitors.lua")
    try:
        with open(out, encoding="utf-8", errors="surrogateescape") as file:
            old = file.read()
    except FileNotFoundError:
        old = None
    existing = [(text, fields, selector_of(fields)) for text, fields in rules(old or "")]
    kept = [e for e in existing if not any(matches(e[2], m) for m in active)]

    def selector(monitor):
        desc = monitor["description"]
        longer = [o["description"] for o in known if o is not monitor] + [e[2][5:] for e in kept if (e[2] or "").startswith("desc:")]
        return monitor["name"] if not desc or any(d.startswith(desc) for d in longer) else f"desc:{desc}"

    selectors = {str(m["id"]): selector(m) for m in known}
    lines = ["-- Generated by the settings app (Display). Previous version: monitors.lua.bak"]
    lines += [e[0] for e in kept]
    for m in active:
        rule = [f'    output = "{lua(selector(m))}",',
                f'    mode = "{m["width"]}x{m["height"]}@{round(m["refreshRate"], 2):g}",',
                f'    position = "{m["x"]}x{m["y"]}",',
                f'    scale = {m["scale"]},']
        mirror = selectors.get(str(m.get("mirrorOf"))) # the number here is only valid for this session
        if mirror:
            rule.append(f'    mirror = "{lua(mirror)}",')
        # From the rule that applied: the last one that matches
        applied = next((e[1] for e in reversed(existing) if matches(e[2], m)), {})
        rule += [f"    {key} = {value}," for key, value in applied.items() if key not in OURS]
        rule.append(f'    transform = {m["transform"]}')
        desc = m["description"].replace("\n", " ")
        lines += [f"-- {desc}\nhl.monitor({{\n" + "\n".join(rule) + "\n})"]

    with open(out + ".tmp", "w", encoding="utf-8", errors="surrogateescape") as file:
        file.write("\n".join(lines) + "\n")
    # A file that doesn't parse stops Hyprland's whole config at this point: the one there is stays
    if shutil.which("luac") and subprocess.run(["luac", "-p", out + ".tmp"], capture_output=True).returncode != 0:
        os.remove(out + ".tmp")
        sys.exit("monitors-save: the result isn't valid Lua, nothing saved")
    if old is not None:
        with open(out + ".bak", "w", encoding="utf-8", errors="surrogateescape") as file:
            file.write(old)
    os.replace(out + ".tmp", out)


if __name__ == "__main__":
    main()

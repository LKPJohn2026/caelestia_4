#!/usr/bin/env python3
"""caelestia4: the screen-share picker of xdg-desktop-portal-hyprland, shown by the shell in Caelestia style.

XDPH runs this as its `screencopy:custom_picker_binary` (~/.config/hypr/xdph.conf) whenever an app asks to share the
screen, and waits for it. It hands over what can be shared in environment variables and reads the choice from stdout:
  XDPH_OUTPUT_SHARING_LIST        <len>:<name>:<x>:<y>:<w>:<h>;...                  (logical geometry)
  XDPH_WINDOW_SHARING_LIST        <handle>[HC>]<class>[HT>]<title>[HE>]<address>[HA>]...
  XDPH_WORKSPACE_SHARING_LIST_V3  <id>[HN>]<len>:<name>[HM>]<n>:<len>:<output>...[HE>]...
  --allow-token                   tick "remember" by default (screencopy:allow_token_by_default)
  stdout: [SELECTION]<flags>/screen:<output> | window:<handle> | workspace-id:<id> | region:<output>@<x>,<y>,<w>,<h>
          (flag r: the app may keep a restore token and share the same thing next time without asking)
  nothing on stdout: cancelled.
Format as of XDPH 1.5.0 (src/shared/ScreencopyShared.cpp, hyprland-share-picker/PickerData.cpp).

This bridge parses the lists into request.json in a private directory under $XDG_RUNTIME_DIR, asks the running shell
(`qs ipc call sharePicker open <dir>`, modules/caelestia/sharePicker) to show the picker, waits for its reply.json,
checks the reply against what XDPH offered and prints the selection. A region is drawn with slurp after the picker
closes, as XDPH's own picker does; cancelling slurp goes back to the picker. When the shell isn't running, or loses the
request mid-way (it stopped), XDPH's own hyprland-share-picker is shown instead, so sharing always works.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time

QS_CONFIG = os.environ.get("CAELESTIA4_QS_CONFIG", "ii")
FALLBACK = "hyprland-share-picker"
TIMEOUT = 300  # s: an unanswered picker gives up (XDPH and the app wait for us meanwhile)
POLL = 0.1
ALIVE_EVERY = 2.0  # s between checks that the shell still has the request


def take_until(s, sep):
    i = s.find(sep)
    return (None, s) if i < 0 else (s[:i], s[i + len(sep):])


def parse_outputs(s):
    out = []
    while s:
        n, s = take_until(s, ":")
        if n is None or not n.isdigit() or int(n) > len(s):
            break
        name, s = s[:int(n)], s[int(n):]
        if not s.startswith(":"):
            break
        fields = []
        rest = s[1:]
        for sep in (":", ":", ":", ";"):
            v, rest = take_until(rest, sep)
            if v is None:
                return out
            fields.append(v)
        s = rest
        try:
            x, y, w, h = (int(v) for v in fields)
        except ValueError:
            continue
        if name and w > 0 and h > 0:
            out.append({"name": name, "x": x, "y": y, "w": w, "h": h})
    return out


def parse_windows(s):
    out = []
    while s:
        handle, s = take_until(s, "[HC>]")
        cls, s = take_until(s, "[HT>]")
        title, s = take_until(s, "[HE>]")
        addr, s = take_until(s, "[HA>]")
        if None in (handle, cls, title, addr):
            break
        if not handle.isdigit():
            continue
        # The Hyprland window address (0 when XDPH has no mapping), as Quickshell's HyprlandToplevel.address spells it
        address = format(int(addr), "x") if addr.isdigit() and int(addr) > 0 else ""
        out.append({"handle": int(handle), "class": cls, "title": title, "address": address})
    return out


def parse_workspaces(s):
    out = []
    while s:
        wid, s = take_until(s, "[HN>]")
        if wid is None or not wid.isdigit():
            break
        n, s = take_until(s, ":")
        if n is None or not n.isdigit() or int(n) > len(s):
            break
        name, s = s[:int(n)], s[int(n):]
        if not s.startswith("[HM>]"):
            break
        s = s[5:]
        count, s = take_until(s, ":")
        if count is None or not count.isdigit():
            break
        outputs = []
        for _ in range(int(count)):
            ln, s = take_until(s, ":")
            if ln is None or not ln.isdigit() or int(ln) > len(s):
                return out
            outputs.append(s[:int(ln)])
            s = s[int(ln):]
        if not s.startswith("[HE>]"):
            break
        s = s[5:]
        if int(wid) > 0:
            out.append({"id": int(wid), "name": name, "outputs": outputs})
    return out


def build_request(env, argv):
    return {
        "outputs": parse_outputs(env.get("XDPH_OUTPUT_SHARING_LIST", "")),
        "windows": parse_windows(env.get("XDPH_WINDOW_SHARING_LIST", "")),
        "workspaces": parse_workspaces(env.get("XDPH_WORKSPACE_SHARING_LIST_V3", "")),
        "allowToken": "--allow-token" in argv,
    }


def format_selection(req, reply):
    """The stdout line for XDPH, or None when the reply is a cancel or names something XDPH didn't offer."""
    if not isinstance(reply, dict):
        return None
    flags = "r" if reply.get("token") is True else ""
    kind, value = reply.get("kind"), reply.get("value")
    if kind == "screen" and any(o["name"] == value for o in req["outputs"]):
        return f"[SELECTION]{flags}/screen:{value}"
    if kind == "window" and type(value) is int and any(w["handle"] == value for w in req["windows"]):
        return f"[SELECTION]{flags}/window:{value}"
    if kind == "workspace" and type(value) is int and any(w["id"] == value for w in req["workspaces"]):
        return f"[SELECTION]{flags}/workspace-id:{value}"
    if kind == "region" and isinstance(value, dict):
        out = next((o for o in req["outputs"] if o["name"] == value.get("output")), None)
        try:
            x, y, w, h = (value[k] for k in ("x", "y", "w", "h"))
        except KeyError:
            return None
        if out is None or not all(type(v) is int for v in (x, y, w, h)):
            return None
        if x < 0 or y < 0 or w <= 0 or h <= 0 or x + w > out["w"] or y + h > out["h"]:
            return None
        return f"[SELECTION]{flags}/region:{out['name']}@{x},{y},{w},{h}"
    return None


def parse_slurp(text, req):
    """slurp -f '%o %X %Y %W %H' (output-relative, logical) -> a region reply value, clamped to the output."""
    parts = text.split()
    if len(parts) != 5:
        return None
    name = parts[0]
    out = next((o for o in req["outputs"] if o["name"] == name), None)
    try:
        x, y, w, h = (int(v) for v in parts[1:])
    except ValueError:
        return None
    if out is None:
        return None
    x, y = max(0, x), max(0, y)
    w, h = min(w, out["w"] - x), min(h, out["h"] - y)
    if w <= 0 or h <= 0:
        return None
    return {"output": name, "x": x, "y": y, "w": w, "h": h}


def qs_call(*args, timeout=5):
    try:
        r = subprocess.run(["qs", "-c", QS_CONFIG, "ipc", "call", "sharePicker", *args],
                           capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout.strip() if r.returncode == 0 else None


def fallback(argv):
    """XDPH's own picker, with what XDPH gave us (it reads the same environment)."""
    try:
        os.execvp(FALLBACK, [FALLBACK, *argv])
    except OSError:
        sys.exit(1)


def ask_shell(d, req):
    """Show the picker in the shell and wait. The reply dict, {} when cancelled or timed out, None when the shell can't
    (or no longer) show it."""
    reply_path = os.path.join(d, "reply.json")
    if os.path.exists(reply_path):
        os.unlink(reply_path)
    if qs_call("open", d) != "ok":
        return None
    start = last_check = time.monotonic()
    while time.monotonic() - start < TIMEOUT:
        try:
            with open(reply_path) as f:
                return json.load(f)
        except FileNotFoundError:
            pass
        except (OSError, ValueError):
            return {}
        now = time.monotonic()
        if now - last_check >= ALIVE_EVERY:
            last_check = now
            state = qs_call("pending", d, timeout=3)
            if state != "yes":
                # One last look for a reply that landed meanwhile; then "no" (a newer request replaced this one, or the
                # shell restarted) is a cancel, and no answer at all (the shell is gone) brings XDPH's picker
                try:
                    with open(reply_path) as f:
                        return json.load(f)
                except (OSError, ValueError):
                    return {} if state == "no" else None
        time.sleep(POLL)
    qs_call("cancel", d)
    return {}


def main(argv, env):
    req = build_request(env, argv)
    runtime = env.get("XDG_RUNTIME_DIR")
    if not runtime or not os.path.isdir(runtime) or not shutil.which("qs"):
        fallback(argv)
    d = tempfile.mkdtemp(prefix="caelestia4-share-", dir=runtime)  # 0700
    use_fallback = False
    try:
        with open(os.path.join(d, "request.json"), "w") as f:
            json.dump(req, f)
        while True:
            reply = ask_shell(d, req)
            if reply is None:
                use_fallback = True  # after the cleanup below: exec doesn't come back to it
                return 0
            if isinstance(reply, dict) and reply.get("kind") == "pick-region":
                if not shutil.which("slurp"):
                    return 0
                r = subprocess.run(["slurp", "-f", "%o %X %Y %W %H"], capture_output=True, text=True)
                value = parse_slurp(r.stdout, req) if r.returncode == 0 else None
                if value is None:
                    continue  # cancelled: back to the picker
                reply = {"kind": "region", "value": value, "token": reply.get("token") is True}
            line = format_selection(req, reply)
            if line:
                sys.stdout.write(line + "\n")
                sys.stdout.flush()
            return 0
    finally:
        shutil.rmtree(d, ignore_errors=True)
        if use_fallback:
            fallback(argv)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:], os.environ))

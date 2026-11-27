#!/usr/bin/env python3
"""caelestia4: checks scripts/caelestia4/share-picker.py, the bridge between xdg-desktop-portal-hyprland and the shell's
screen-share picker (modules/caelestia/sharePicker).

  python3 -I tools/tests/share-picker/run.py

1. XDPH's lists (outputs, windows, workspaces V3; format of XDPH 1.5.0) parse, names with the delimiters in them too.
2. Only what XDPH offered reaches stdout: an output, window handle or workspace id it didn't list, a wrong type (true
   for a number), a region outside its output, a garbled reply: nothing printed (a cancel for XDPH).
3. Run for real with stub commands (qs answering as the shell would, slurp, hyprland-share-picker) in a fake
   XDG_RUNTIME_DIR: a choice is printed with the restore flag only when asked; cancel prints nothing; a region comes
   from slurp, a cancelled slurp goes back to the picker; no shell -> XDPH's own picker; a request another one
   replaced -> cancel; the private directory is removed afterwards.

Never touches the desktop, the real shell or the network.
"""
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
SCRIPT = REPO / "dots/.config/quickshell/ii/scripts/caelestia4/share-picker.py"

fails = 0


def check(cond, what):
    global fails
    if cond:
        print(f"ok: {what}")
    else:
        fails += 1
        print(f"FAIL: {what}")


spec = importlib.util.spec_from_file_location("share_picker", SCRIPT)
sp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sp)

# ---- 1. parsing ----
odd = "OUT:B;2"  # an output name with the list's own delimiters in it (lengths make it unambiguous)
OUTPUTS = f"5:OUT-A:0:0:2560:1440;{len(odd)}:{odd}:2560:0:1920:1080;5:OUT-C:0:0:0:1080;"
outs = sp.parse_outputs(OUTPUTS)
check([o["name"] for o in outs] == ["OUT-A", odd], "outputs parse, a zero-sized one is left out")
check(outs[1] == {"name": odd, "x": 2560, "y": 0, "w": 1920, "h": 1080}, "output geometry")
check(sp.parse_outputs("99:short") == [], "an output whose length runs past the list stops the parse")

WINDOWS = "123[HC>]kitty[HT>]~ : zsh[HE>]94571234567890[HA>]456[HC>]zoom[HT>]Meeting[HE>]0[HA>]x[HC>]a[HT>]b[HE>]1[HA>]"
wins = sp.parse_windows(WINDOWS)
check([w["handle"] for w in wins] == [123, 456], "windows parse, a non-numeric handle is left out")
check(wins[0]["address"] == format(94571234567890, "x") and wins[1]["address"] == "", "window address as hex, 0 = none")
check(wins[0]["title"] == "~ : zsh" and wins[1]["class"] == "zoom", "window class and title")

ws_name = "web[HE>]x"  # delimiters inside a name, again
WORKSPACES = f"7[HN>]1:1[HM>]1:5:OUT-A[HE>]9[HN>]{len(ws_name)}:{ws_name}[HM>]2:5:OUT-A5:OUT-B[HE>]0[HN>]1:z[HM>]0:[HE>]"
wss = sp.parse_workspaces(WORKSPACES)
check([w["id"] for w in wss] == [7, 9], "workspaces parse, id 0 is left out")
check(wss[1] == {"id": 9, "name": ws_name, "outputs": ["OUT-A", "OUT-B"]}, "workspace name and outputs")

ENV = {"XDPH_OUTPUT_SHARING_LIST": OUTPUTS, "XDPH_WINDOW_SHARING_LIST": WINDOWS,
       "XDPH_WORKSPACE_SHARING_LIST_V3": WORKSPACES}
req = sp.build_request(ENV, ["--allow-token"])
check(req["allowToken"] is True and sp.build_request(ENV, [])["allowToken"] is False, "--allow-token")

# ---- 2. only what was offered ----
fmt = sp.format_selection
check(fmt(req, {"kind": "screen", "value": "OUT-A"}) == "[SELECTION]/screen:OUT-A", "screen")
check(fmt(req, {"kind": "screen", "value": "OUT-A", "token": True}) == "[SELECTION]r/screen:OUT-A", "restore flag")
check(fmt(req, {"kind": "screen", "value": "OUT-A", "token": "yes"}) == "[SELECTION]/screen:OUT-A", "token must be true")
check(fmt(req, {"kind": "window", "value": 456}) == "[SELECTION]/window:456", "window")
check(fmt(req, {"kind": "workspace", "value": 9}) == "[SELECTION]/workspace-id:9", "workspace")
check(fmt(req, {"kind": "region", "value": {"output": "OUT-A", "x": 10, "y": 20, "w": 300, "h": 200}})
      == "[SELECTION]/region:OUT-A@10,20,300,200", "region")
bad = [
    {"kind": "screen", "value": "OUT-Z"},
    {"kind": "screen", "value": "OUT-A\n[SELECTION]/screen:OUT-B"},
    {"kind": "window", "value": 999},
    {"kind": "window", "value": "123"},
    {"kind": "window", "value": True},
    {"kind": "workspace", "value": 7.0},
    {"kind": "region", "value": {"output": "OUT-A", "x": 2500, "y": 0, "w": 100, "h": 10}},
    {"kind": "region", "value": {"output": "OUT-A", "x": -1, "y": 0, "w": 10, "h": 10}},
    {"kind": "region", "value": {"output": "OUT-A", "x": 0, "y": 0, "w": 0, "h": 10}},
    {"kind": "region", "value": {"output": "OUT-A", "x": 0, "y": 0}},
    {"kind": "cancel"},
    {"kind": "pick-region"},
    [],
    "screen",
]
check(all(fmt(req, b) is None for b in bad), "anything not offered, malformed or a cancel prints nothing")
check(sp.parse_slurp("OUT-A 2500 1400 200 100\n", req) == {"output": "OUT-A", "x": 2500, "y": 1400, "w": 60, "h": 40},
      "slurp region clamped to its output")
check(sp.parse_slurp("OUT-Z 0 0 10 10", req) is None and sp.parse_slurp("", req) is None, "bad slurp output")

# ---- 3. for real, with stubs ----
QS_STUB = r"""#!/usr/bin/env python3
import json, os, sys
# qs -c ii ipc call sharePicker <fn> <dir>
fn, d = sys.argv[6], sys.argv[7]
log = os.environ["STUB_LOG"]
with open(log, "a") as f:
    f.write(f"{fn} {os.path.basename(d)}\n")
mode = os.environ["STUB_MODE"]
if mode == "gone":
    sys.exit(1)
if fn == "open":
    opens = open(log).read().count("open ")
    replies = json.loads(os.environ["STUB_REPLIES"])
    r = replies[min(opens, len(replies)) - 1]
    if r is not None:
        with open(os.path.join(d, "reply.json"), "w") as f:
            json.dump(r, f)
    print("ok")
elif fn == "pending":
    print("no" if mode == "replaced" else "yes")
"""
SLURP_STUB = "#!/bin/sh\n[ -n \"$STUB_SLURP\" ] || exit 1\necho \"$STUB_SLURP\"\n"
FALLBACK_STUB = "#!/bin/sh\necho \"[SELECTION]/screen:FROM-FALLBACK $*\"\n"


def run(replies, mode="shell", slurp="", argv=()):
    with tempfile.TemporaryDirectory() as t:
        t = Path(t)
        bin_ = t / "bin"
        bin_.mkdir()
        for name, body in (("qs", QS_STUB), ("slurp", SLURP_STUB), ("hyprland-share-picker", FALLBACK_STUB)):
            (bin_ / name).write_text(body)
            (bin_ / name).chmod(0o755)
        rt = t / "run"
        rt.mkdir(mode=0o700)
        env = {**ENV, "PATH": f"{bin_}:/usr/bin:/bin", "XDG_RUNTIME_DIR": str(rt), "HOME": str(t),
               "STUB_LOG": str(t / "log"), "STUB_MODE": mode, "STUB_REPLIES": json.dumps(replies),
               "STUB_SLURP": slurp}
        r = subprocess.run([sys.executable, "-I", str(SCRIPT), *argv], env=env, capture_output=True, text=True,
                           timeout=30)
        log = (t / "log").read_text() if (t / "log").exists() else ""
        left = sorted(p.name for p in rt.iterdir())
        return r.stdout, log, left


out, log, left = run([{"kind": "window", "value": 123, "token": True}])
check(out == "[SELECTION]r/window:123\n", "a window chosen in the shell reaches XDPH")
check(left == [], "the private directory is removed")
check(all(line.split()[1].startswith("caelestia4-share-") for line in log.splitlines()), "the shell is given its directory")

out, _, _ = run([{"kind": "cancel"}])
check(out == "", "cancel prints nothing")

out, _, _ = run([{"kind": "screen", "value": "OUT-Z"}])
check(out == "", "a screen XDPH didn't offer prints nothing")

out, log, _ = run([{"kind": "pick-region", "token": False}], slurp="OUT-A 5 6 70 80")
check(out == "[SELECTION]/region:OUT-A@5,6,70,80\n", "region from slurp")

out, log, _ = run([{"kind": "pick-region"}, {"kind": "screen", "value": "OUT-A"}], slurp="")
check(out == "[SELECTION]/screen:OUT-A\n" and log.count("open ") == 2, "a cancelled slurp goes back to the picker")

out, log, left = run([None], mode="gone", argv=["--allow-token"])
check(out.startswith("[SELECTION]/screen:FROM-FALLBACK --allow-token"), "no shell: XDPH's own picker, same arguments")
check(left == [], "the private directory is removed before the fallback")

out, _, _ = run([None], mode="replaced")
check(out == "", "a request another one replaced is a cancel")

if fails:
    print(f"share-picker: {fails} FAILED")
    sys.exit(1)
print("share-picker: OK")

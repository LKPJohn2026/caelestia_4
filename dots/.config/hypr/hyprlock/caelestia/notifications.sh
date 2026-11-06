#!/usr/bin/env bash
# caelestia4 hyprlock: notifications card (Caelestia's lock shows the notification list too).
# Reads the shell's notification store (Caelestia's Notifs: $XDG_STATE_HOME/caelestia/notifs.json; end-4's old one as
# a fallback):
# a count, then the newest few as "app · summary   HH:MM". Only app and summary, never the body: anyone at the
# screen can read it.
source "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/scripts/caelestia4/tr.sh" 2>/dev/null || _tr_catalogue() { _tr_file=""; }
_tr_catalogue
exec python3 -I - "${_tr_file:-}" "${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/notifs.json" "${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/notifications/notifications.json" <<'EOF'
import html, json, sys, time

SHOW = 4      # newest notifications listed
WIDTH = 42    # characters per line before "…"

from datetime import datetime

def when_ms(n):
    t = n.get("time", 0)
    if isinstance(t, (int, float)):  # end-4: epoch ms
        return t
    try:  # Caelestia: ISO date string
        return datetime.fromisoformat(str(t).replace("Z", "+00:00")).timestamp() * 1000
    except ValueError:
        return 0

try:
    with open(sys.argv[1]) as f:
        catalogue = json.load(f)
except (OSError, ValueError):
    catalogue = {}

def tr(text, *args):
    text = str(catalogue.get(text) or text).removesuffix("/*keep*/").strip()
    for i, arg in enumerate(args, 1):
        text = text.replace(f"%{i}", str(arg))
    return text

notifs = []
for path in sys.argv[2:]:
    try:
        with open(path) as f:
            notifs = json.load(f)
        break
    except Exception:
        continue

notifs = sorted((n for n in notifs if isinstance(n, dict)), key=when_ms, reverse=True)
if not notifs:
    print(f'<span alpha="70%">{tr("No notifications")}</span>')
    sys.exit()

def cut(s, n):
    s = " ".join(str(s or "").split())
    return s if len(s) <= n else s[: n - 1] + "…"

print(f"<b>{tr('%1 notifications', len(notifs))}</b>")
for n in notifs[:SHOW]:
    app = cut(n.get("appName") or tr("Application"), 16)
    summary = cut(n.get("summary"), WIDTH - len(app) - 3)
    when = time.strftime("%H:%M", time.localtime(when_ms(n) / 1000))
    print(f'<span alpha="70%">{html.escape(app)} ·</span> {html.escape(summary)}  <span alpha="50%">{when}</span>')
if len(notifs) > SHOW:
    print(f'<span alpha="50%">{tr("and %1 more", len(notifs) - SHOW)}</span>')
EOF

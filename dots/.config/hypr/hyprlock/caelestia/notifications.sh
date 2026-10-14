#!/usr/bin/env bash
# caelestia4 hyprlock: notifications card (Caelestia's lock shows the notification list too).
# Reads end-4's notification store (the shell keeps it in ~/.cache/quickshell/notifications/notifications.json):
# a count, then the newest few as "app · summary   HH:MM". Only app and summary, never the body: anyone at the
# screen can read it.
exec python3 -I - "${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/notifications/notifications.json" <<'EOF'
import html, json, sys, time

SHOW = 4      # newest notifications listed
WIDTH = 42    # characters per line before "…"

try:
    with open(sys.argv[1]) as f:
        notifs = json.load(f)
except Exception:
    notifs = []

notifs = sorted((n for n in notifs if isinstance(n, dict)), key=lambda n: n.get("time", 0), reverse=True)
if not notifs:
    print('<span alpha="70%">Không có thông báo</span>')
    sys.exit()

def cut(s, n):
    s = " ".join(str(s or "").split())
    return s if len(s) <= n else s[: n - 1] + "…"

print(f"<b>{len(notifs)} thông báo</b>")
for n in notifs[:SHOW]:
    app = cut(n.get("appName") or "Ứng dụng", 16)
    summary = cut(n.get("summary"), WIDTH - len(app) - 3)
    when = time.strftime("%H:%M", time.localtime(n.get("time", 0) / 1000))
    print(f'<span alpha="70%">{html.escape(app)} ·</span> {html.escape(summary)}  <span alpha="50%">{when}</span>')
if len(notifs) > SHOW:
    print(f'<span alpha="50%">và {len(notifs) - SHOW} thông báo khác</span>')
EOF

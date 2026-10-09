#!/usr/bin/env bash
# caelestia4 hyprlock: weather line, cached 30 min so the lock never waits on the network
cache="${XDG_RUNTIME_DIR:-/tmp}/caelestia4-lock-weather"
if [[ ! -s "$cache" || $(( $(date +%s) - $(stat -c %Y "$cache") )) -gt 1800 ]]; then
  w=$(curl -sf --max-time 4 'https://wttr.in/?format=%c%t|%C|%l' 2>/dev/null) && [[ "$w" != *Unknown* ]] && echo "$w" > "$cache"
fi
[[ -s "$cache" ]] || { echo "Weather unavailable"; exit 0; }
IFS='|' read -r temp cond loc < "$cache"
printf '<span font_size="xx-large">%s</span>\n<span alpha="70%%">%s · %s</span>\n' "$(echo "$temp" | xargs)" "$(echo "$cond" | xargs)" "${loc%%,*}"

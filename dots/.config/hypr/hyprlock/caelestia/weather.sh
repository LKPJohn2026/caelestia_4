#!/usr/bin/env bash
source "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/scripts/caelestia4/tr.sh" 2>/dev/null || { tr_() { printf '%s' "$1"; }; tr_pad() { printf '%s  ' "$1"; }; }
# caelestia4 hyprlock: weather line, cached 30 min so the lock never waits on the network. In the shell's language, and
# from its city and units (Bar > Weather); with no city set wttr.in goes by the IP address
_tr_catalogue 2>/dev/null
lang=$(basename "${_tr_file:-en}" .json); lang=${lang%%_*}
config="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"
city=$(jq -r '.bar.weather.city // ""' "$config" 2>/dev/null)
units=$([[ $(jq -r '.bar.weather.useUSCS // false' "$config" 2>/dev/null) == true ]] && echo u || echo m)
cache="${XDG_RUNTIME_DIR:-/tmp}/caelestia4-lock-weather-$lang-$units-${city//[^[:alnum:]]/_}"
if [[ ! -s "$cache" || $(( $(date +%s) - $(stat -c %Y "$cache") )) -gt 1800 ]]; then
  w=$(curl -sfG --max-time 4 --data-urlencode "lang=$lang" --data "$units" --data-urlencode 'format=%c%t|%C|%l' \
      "https://wttr.in/$(jq -rn --arg c "$city" '$c | @uri')" 2>/dev/null) && [[ "$w" != *Unknown* ]] && echo "$w" > "$cache"
fi
[[ -s "$cache" ]] || { tr_ "No weather data"; echo; exit 0; }
IFS='|' read -r temp cond loc < "$cache"
printf '<span font_size="xx-large">%s</span>\n<span alpha="70%%">%s · %s</span>\n' "$(echo "$temp" | xargs)" "$(echo "$cond" | xargs)" "${loc%%,*}"

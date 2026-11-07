#!/usr/bin/env bash
# caelestia4: write hypr/hyprlock/layout.conf, which hyprlock.conf sources: the three-column layout on a screen with room
# for it, the centre column alone on any other. hyprlock's sizes are device pixels (its surface is the output's full
# resolution, whatever the scale), so `width`/`height` decide, swapped on a rotated output.
# A widget names one monitor or all of them, so screens that differ mean one copy of the layout per screen. The password
# field then stays unnamed (it is the same in both layouts): a screen that appears during the lock, or comes back under
# another connector, always has it. Runs before each lock: whatever goes wrong here keeps the file there is, and hyprlock
# still starts.
dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock"
out="$dir/layout.conf"
[[ -f "$dir/layout-full.conf" && -f "$dir/layout-compact.conf" ]] || exit 0 # an install from before these files
monitors=$(timeout 2 hyprctl monitors -j 2>/dev/null) &&
    list=$(jq -r '.[] | (if .transform % 2 == 1 then [.height, .width] else [.width, .height] end) as [$w, $h]
        | "\(.name) \(if $w >= 1820 and $h >= 900 then "full" else "compact" end)"' <<<"$monitors" 2>/dev/null) &&
    [[ -n "$list" ]] || list=""

tmp="$out.$$"
trap 'rm -f -- "$tmp"' EXIT
if [[ -z "$list" ]]; then
    [[ -f "$out" ]] && exit 0 # keep the last one; with none yet, the layout that shows everything
    cat "$dir/layout-full.conf" >"$tmp" || exit 0
elif [[ $(cut -d' ' -f2 <<<"$list" | sort -u | wc -l) == 1 ]]; then
    cat "$dir/layout-$(head -1 <<<"$list" | cut -d' ' -f2).conf" >"$tmp" || exit 0
else
    while read -r name layout; do
        awk '/^input-field \{/ { skip = 1 } !skip { print } skip && /^\}/ { skip = 0 }' "$dir/layout-$layout.conf" |
            sed -E "s/^([[:space:]]*monitor[[:space:]]*=).*/\1 $name/" >>"$tmp" || exit 0
    done <<<"$list"
    sed -n '/^input-field {/,/^}/p' "$dir/layout-full.conf" >>"$tmp" || exit 0
fi
mv -f -- "$tmp" "$out"

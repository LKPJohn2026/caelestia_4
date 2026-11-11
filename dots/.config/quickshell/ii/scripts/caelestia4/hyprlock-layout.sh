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
trap 'rm -f -- "$tmp" "$tmp.face"' EXIT
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
# The avatar when there is one, for all screens: it sits at the same place in both layouts. hyprlock doesn't crop, and
# ~/.face can be any picture, so it gets a square copy; with none (no magick, not an image) the person symbol stays.
face="$HOME/.face"
square="${XDG_CACHE_HOME:-$HOME/.cache}/caelestia4/lock-face.png"
if [[ -s "$face" ]]; then
    if [[ ! -s "$square" || "$face" -nt "$square" ]]; then
        mkdir -p "$(dirname "$square")"
        timeout 3 magick "${face}[0]" -auto-orient -gravity center -extent '%[fx:min(w,h)]x%[fx:min(w,h)]' "PNG:$square.$$" 2>/dev/null &&
            mv -f -- "$square.$$" "$square" || { rm -f -- "$square.$$" "$square"; }
    fi
    if [[ -s "$square" ]]; then
        awk 'BEGIN { RS = ""; ORS = "\n\n" } !/text = person/' "$tmp" >"$tmp.face" && mv -f -- "$tmp.face" "$tmp" || exit 0
        cat >>"$tmp" <<CONF || exit 0
image {
    monitor =
    path = $square
    size = 112
    rounding = -1
    border_size = 0
    position = 0, -110
    halign = center
    valign = center
    zindex = 3
}
CONF
    fi
fi
mv -f -- "$tmp" "$out"

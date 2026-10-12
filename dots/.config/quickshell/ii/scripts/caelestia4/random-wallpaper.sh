#!/usr/bin/env bash
# caelestia4: download a random wallpaper and apply it (settings app > Appearance > Wallpaper).
# Usage: random-wallpaper.sh <wallhaven|konachan|yandere> [min-w min-h [ratio-w ratio-h]]
#   min-w/min-h  "Only wallpapers that fill my screen": at least this size (0 0 = any size)
#   ratio-w/h    "Prefer my screen's shape": e.g. 7680 2160 (reduced to 32:9); omitted = any landscape
# Priority: 1) exactly the monitor's resolution (when a size is given), 2) the screen's shape (aspect ratio),
# 3) the closest shape / any landscape. Servers filter where they can (Wallhaven `resolutions=`, `ratios=`,
# `atleast=`; Moebooru `width:>= height:>=`); for Moebooru the shape is ranked in a batch of 100 random posts.
# Saved to <Pictures>/Wallpapers/random_wallpaper[-1].<ext> like end-4's scripts (alternating, so the new file never
# replaces the one in use), then applied with switchwall.sh. One status line per step; exit 2 = nothing matched.
# DRYRUN=1 stops before downloading.
set -uo pipefail
source=${1:-wallhaven} minw=${2:-0} minh=${3:-0} rw=${4:-0} rh=${5:-0}
ua="caelestia4-wallpaper/1.0"
dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Wallpapers"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"
switchwall="$(dirname "$0")/../colors/switchwall.sh"
mkdir -p "$dir"

gcd() { local a=$1 b=$2; while (( b )); do local t=$b; b=$((a % b)); a=$t; done; echo "$a"; }
ratio="" target=0
if (( rw > 0 && rh > 0 )); then
  g=$(gcd "$rw" "$rh"); ratio="$((rw / g))x$((rh / g))"
  target=$(echo "scale=6; $rw / $rh" | bc)
fi
sizeq="" sizetags=""
(( minw > 0 )) && sizeq="&atleast=${minw}x${minh}" && sizetags="width:>=$minw height:>=$minh"
tier=""

echo "Searching $source…"
wallhaven() { # wallhaven <extra query> -> "path WxH"
  curl -fsS -m 20 -A "$ua" "https://wallhaven.cc/api/v1/search?categories=110&purity=100&sorting=random$1" \
    | jq -r '.data[0] // empty | "\(.path) \(.resolution)"'
}
moebooru() { # moebooru <host> <tags> <limit> <jq filter on the post list> -> "url WxH tier"
  curl -fsS -m 20 -A "$ua" -G "https://$1/post.json" --data-urlencode "tags=rating:safe order:random $2" --data-urlencode "limit=$3" \
    | jq -r "$4 // empty | \"\\(.file_url) \\(.width)x\\(.height) \\(.t // \"\")\""
}

case "$source" in
  wallhaven)
    (( minw > 0 )) && read -r link size < <(wallhaven "&resolutions=${minw}x${minh}") && tier="exact size"
    [[ -z "${link:-}" && -n "$ratio" ]] && read -r link size < <(wallhaven "&ratios=$ratio$sizeq") && tier="same shape ${ratio/x/:}"
    [[ -z "${link:-}" ]] && read -r link size < <(wallhaven "&ratios=landscape$sizeq") && tier="landscape"
    ;;
  konachan | yandere)
    host=$([[ $source == konachan ]] && echo konachan.net || echo yande.re)
    (( minw > 0 )) && read -r link size t < <(moebooru "$host" "width:$minw height:$minh" 20 '.[0]') && tier="exact size"
    if [[ -z "${link:-}" ]]; then
      if [[ -n "$ratio" ]]; then
        # 100 random (large enough) posts: landscape ones ranked by how close their shape is to the screen's;
        # within 2 % counts as the same shape
        read -r link size t < <(moebooru "$host" "$sizetags" 100 \
          "[.[] | select(.width > .height) | . + {d: (((.width / .height) - $target | fabs) / $target)}] | sort_by(.d) | .[0] | if . then . + {t: (if .d < 0.02 then \"same\" else \"closest\" end)} else empty end")
        [[ "${t:-}" == same ]] && tier="same shape ${ratio/x/:}" || tier="closest shape"
      else
        # Moebooru can't filter orientation; portrait looks wrong as a wallpaper
        read -r link size t < <(moebooru "$host" "$sizetags" 50 '[.[] | select(.width > .height)][0]')
        tier="landscape"
      fi
    fi
    ;;
  *) echo "Unknown source: $source"; exit 1 ;;
esac

if [[ -z "${link:-}" ]]; then
  (( minw > 0 )) && echo "No wallpaper of ${minw}×${minh} or larger on $source right now" || echo "$source returned nothing"
  exit 2
fi

[[ -n "${DRYRUN:-}" ]] && { echo "Would download ${size/x/×} [$tier]: $link"; exit 0; } # testing

ext="${link##*.}"; ext="${ext%%\?*}"
path="$dir/random_wallpaper.$ext"
[[ "$path" == "$(jq -r '.background.wallpaperPath' "$cfg" 2>/dev/null)" ]] && path="$dir/random_wallpaper-1.$ext"

echo "Downloading ${size/x/×} ($tier)…"
curl -fsS -m 120 -A "$ua" -o "$path" "$link" || { echo "Download failed"; exit 1; }
echo "Applying…"
"$switchwall" --image "$path" >/dev/null 2>&1
echo "Done: ${size/x/×} from $source ($tier)"

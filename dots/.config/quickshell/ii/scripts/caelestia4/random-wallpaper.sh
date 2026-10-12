#!/usr/bin/env bash
# caelestia4: download a random wallpaper and apply it (settings app > Appearance > Wallpaper).
# Usage: random-wallpaper.sh <wallhaven|konachan|yandere> [min-width min-height]
# With a minimum size, only images at least that large are asked for (the servers filter: Wallhaven `atleast=`,
# Moebooru `width:>= height:>=`). Saved to <Pictures>/Wallpapers/random_wallpaper[-1].<ext> like end-4's scripts
# (alternating, so the new file never replaces the one in use), then applied with switchwall.sh.
# Prints one status line per step; exit 2 = nothing matched.
set -uo pipefail
source=${1:-wallhaven} minw=${2:-0} minh=${3:-0}
ua="caelestia4-wallpaper/1.0"
dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Wallpapers"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"
switchwall="$(dirname "$0")/../colors/switchwall.sh"
mkdir -p "$dir"

echo "Searching $source…"
# With a minimum size the best fit wins: 1) exactly the monitor's resolution, 2) the same shape (aspect ratio) and at
# least as large, so nothing is cropped, 3) any landscape image at least as large. $tier says which one matched.
gcd() { local a=$1 b=$2; while (( b )); do local t=$b; b=$((a % b)); a=$t; done; echo "$a"; }
tier=""
wallhaven() { # wallhaven <extra query> -> "path WxH"
  curl -fsS -m 20 -A "$ua" "https://wallhaven.cc/api/v1/search?categories=110&purity=100&sorting=random$1" \
    | jq -r '.data[0] // empty | "\(.path) \(.resolution)"'
}
moebooru() { # moebooru <host> <size tags> <limit> <jq filter on the post list> -> "url WxH"
  curl -fsS -m 20 -A "$ua" -G "https://$1/post.json" --data-urlencode "tags=rating:safe order:random $2" --data-urlencode "limit=$3" \
    | jq -r "$4 // empty | \"\\(.file_url) \\(.width)x\\(.height) \\(.t // \"\")\""
}
case "$source" in
  wallhaven)
    if (( minw > 0 )); then
      g=$(gcd "$minw" "$minh"); ratio="$((minw / g))x$((minh / g))"
      read -r link size < <(wallhaven "&resolutions=${minw}x${minh}") && tier="exact"
      [[ -z "${link:-}" ]] && read -r link size < <(wallhaven "&ratios=$ratio&atleast=${minw}x${minh}") && tier="same shape ($ratio)"
      [[ -z "${link:-}" ]] && read -r link size < <(wallhaven "&ratios=landscape&atleast=${minw}x${minh}") && tier="larger"
    else
      read -r link size < <(wallhaven "&ratios=landscape")
    fi
    ;;
  konachan | yandere)
    host=$([[ $source == konachan ]] && echo konachan.net || echo yande.re)
    if (( minw > 0 )); then
      read -r link size < <(moebooru "$host" "width:$minw height:$minh" 20 '.[0]') && tier="exact"
      if [[ -z "${link:-}" ]]; then
        # one batch of 100 large posts: exact size, then same shape (within 2 %), then the first landscape one
        target=$(echo "scale=6; $minw / $minh" | bc)
        read -r link size t < <(moebooru "$host" "width:>=$minw height:>=$minh" 100 \
          "([.[] | select(.width == $minw and .height == $minh)][0] | if . then . + {t: \"exact\"} else empty end) // ([.[] | select(((.width / .height) - $target | fabs) / $target < 0.02)][0] | if . then . + {t: \"shape\"} else empty end) // ([.[] | select(.width > .height)][0] | if . then . + {t: \"larger\"} else empty end)")
        case "${t:-}" in exact) tier="exact" ;; shape) tier="same shape" ;; *) tier="larger" ;; esac
      fi
    else
      # 50 random posts, first landscape one (Moebooru can't filter orientation; portrait looks wrong as a wallpaper)
      read -r link size < <(moebooru "$host" "" 50 '[.[] | select(.width > .height)][0]')
    fi
    ;;
  *) echo "Unknown source: $source"; exit 1 ;;
esac

if [[ -z "${link:-}" ]]; then
  (( minw > 0 )) && echo "No wallpaper of ${minw}×${minh} or larger on $source right now" || echo "$source returned nothing"
  exit 2
fi

[[ -n "${DRYRUN:-}" ]] && { echo "Would download ${size/x/×}${tier:+ [$tier]}: $link"; exit 0; } # testing

ext="${link##*.}"; ext="${ext%%\?*}"
path="$dir/random_wallpaper.$ext"
[[ "$path" == "$(jq -r '.background.wallpaperPath' "$cfg" 2>/dev/null)" ]] && path="$dir/random_wallpaper-1.$ext"

echo "Downloading ${size/x/×}…"
curl -fsS -m 120 -A "$ua" -o "$path" "$link" || { echo "Download failed"; exit 1; }
echo "Applying…"
"$switchwall" --image "$path" >/dev/null 2>&1
echo "Done: ${size/x/×} from $source${tier:+ ($tier)}"

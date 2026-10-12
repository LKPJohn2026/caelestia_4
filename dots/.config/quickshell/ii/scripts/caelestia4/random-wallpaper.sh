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
case "$source" in
  wallhaven)
    url="https://wallhaven.cc/api/v1/search?categories=110&purity=100&sorting=random&ratios=landscape"
    (( minw > 0 )) && url+="&atleast=${minw}x${minh}"
    read -r link size < <(curl -fsS -m 20 -A "$ua" "$url" | jq -r '.data[0] // empty | "\(.path) \(.resolution)"')
    ;;
  konachan | yandere)
    host=$([[ $source == konachan ]] && echo konachan.net || echo yande.re)
    tags="rating:safe order:random"
    (( minw > 0 )) && tags+=" width:>=$minw height:>=$minh"
    # 50 random posts, first landscape one (Moebooru can't filter orientation; portrait looks wrong as a wallpaper)
    read -r link size < <(curl -fsS -m 20 -A "$ua" -G "https://$host/post.json" --data-urlencode "tags=$tags" --data-urlencode "limit=50" \
      | jq -r '[.[] | select(.width > .height)][0] // empty | "\(.file_url) \(.width)x\(.height)"')
    ;;
  *) echo "Unknown source: $source"; exit 1 ;;
esac

if [[ -z "${link:-}" ]]; then
  (( minw > 0 )) && echo "No wallpaper of ${minw}×${minh} or larger on $source right now" || echo "$source returned nothing"
  exit 2
fi

[[ -n "${DRYRUN:-}" ]] && { echo "Would download ${size/x/×}: $link"; exit 0; } # testing

ext="${link##*.}"; ext="${ext%%\?*}"
path="$dir/random_wallpaper.$ext"
[[ "$path" == "$(jq -r '.background.wallpaperPath' "$cfg" 2>/dev/null)" ]] && path="$dir/random_wallpaper-1.$ext"

echo "Downloading ${size/x/×}…"
curl -fsS -m 120 -A "$ua" -o "$path" "$link" || { echo "Download failed"; exit 1; }
echo "Applying…"
"$switchwall" --image "$path" >/dev/null 2>&1
echo "Done: ${size/x/×} from $source"

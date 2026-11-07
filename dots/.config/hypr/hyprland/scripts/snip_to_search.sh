#!/usr/bin/env bash
image="${XDG_RUNTIME_DIR:-/tmp}/caelestia4-search.png"
trap 'rm -f -- "$image"' EXIT
region=$(slurp) || exit 0
grim -g "$region" "$image" || exit 1
imageLink=$(curl -sF "files[]=@$image" 'https://uguu.se/upload' | jq -r '.files[0].url')
[[ -n "$imageLink" && "$imageLink" != null ]] || exit 1
xdg-open "https://lens.google.com/uploadbyurl?url=${imageLink}"

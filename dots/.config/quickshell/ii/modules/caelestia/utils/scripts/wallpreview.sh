#!/usr/bin/env bash
# caelestia4: colours a wallpaper would give, without applying anything (Caelestia's `caelestia wallpaper -p`).
# Same generator and colour style as end-4's switchwall.sh: matugen, palette.type from the config ("auto" = end-4's
# scheme_for_image.py pick). Prints matugen's JSON (colors.<role>.default.color) on stdout; nothing is written.
# Usage: wallpreview.sh <image> <dark|light>
img="$1"
mode="${2:-dark}"
[[ -f "$img" ]] || exit 1

type=$(jq -r '.appearance.palette.type // "auto"' "${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json" 2>/dev/null)
if [[ "$type" == "auto" || -z "$type" ]]; then
    venv=$(eval echo "${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$HOME/.local/state/quickshell/.venv}")
    type=$("$venv/bin/python3" "$(dirname "$0")/../../../../scripts/colors/scheme_for_image.py" "$img" 2>/dev/null | tr -d '\n')
    [[ "$type" == scheme-* ]] || type=scheme-tonal-spot
fi

exec matugen image "$img" --dry-run -j hex -m "$mode" -t "$type" --source-color-index 0

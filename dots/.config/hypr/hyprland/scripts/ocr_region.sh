#!/usr/bin/env bash
# caelestia4: the shell's region OCR when the shell isn't running
image="${XDG_RUNTIME_DIR:-/tmp}/caelestia4-ocr.png"
trap 'rm -f -- "$image"' EXIT
region=$(slurp $SLURP_ARGS) || exit 0
grim -g "$region" "$image" || exit 1
langs=$(tesseract --list-langs | awk 'NR > 1 { print $1 }' | paste -sd+)
text=$(tesseract "$image" stdout -l "$langs") || exit 1
printf '%s' "$text" | wl-copy

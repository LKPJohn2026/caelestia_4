#!/usr/bin/env bash
# caelestia4: make Material Symbols Rounded Outline and Filled, the shell's icons for a scaled desktop widget
# (modules/common/widgets/MaterialSymbol.qml). The variable font keeps its glyphs' overlapping outlines (a filled play
# button's, the note over the page in "lyrics"), and Qt's curve renderer, which keeps a scaled widget's icons sharp,
# draws the overlaps as holes; these are two static instances (FILL 0 at weight 400 and FILL 1 at weight 600, as a
# MaterialSymbol has them, GRAD 0, optical size 20, most widget icons' size) with the overlaps merged.
# Re-run after the ttf-material-symbols-variable package updates. Needs fontTools and skia-pathops, in a venv here.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="/usr/share/fonts/ttf-material-symbols-variable/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf"
DEST="$REPO/dots/.config/quickshell/ii/modules/caelestia/assets/material-symbols-static"
VENV="${XDG_CACHE_HOME:-$HOME/.cache}/caelestia4/fontvenv"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP:?}"' EXIT

[[ -x "$VENV/bin/python" ]] || { python3 -m venv "$VENV" && "$VENV/bin/pip" install -q fonttools skia-pathops; }
mkdir -p "$DEST"
# style, FILL, weight
for spec in "Outline 0 400" "Filled 1 600"; do
    read -r style fill weight <<<"$spec"
    "$VENV/bin/fonttools" varLib.instancer "$SRC" FILL="$fill" wght="$weight" GRAD=0 opsz=20 --remove-overlaps \
        -o "$TMP/$style.ttf"
    "$VENV/bin/python" - "$TMP/$style.ttf" "$DEST/MaterialSymbolsRounded$style.ttf" "$style" <<'EOF'
import sys
from fontTools.ttLib import TTFont
font = TTFont(sys.argv[1])
family = f"Material Symbols Rounded {sys.argv[3]}"  # its own family: never taken for the variable font
names = {1: family, 2: "Regular", 4: family, 6: family.replace(" ", "") + "-Regular", 16: family, 17: "Regular"}
for record in font["name"].names:
    if record.nameID in names:
        record.string = names[record.nameID]
font["OS/2"].usWeightClass = 400
font.save(sys.argv[2])
EOF
    echo "wrote $DEST/MaterialSymbolsRounded$style.ttf"
done

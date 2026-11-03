#!/usr/bin/env bash
# caelestia4: make Material Symbols Rounded Filled, the shell's filled icons for a scaled desktop widget
# (modules/common/widgets/MaterialSymbol.qml). The variable font keeps its glyphs' overlapping outlines, and Qt's
# curve renderer, which keeps a scaled widget's icons sharp, draws the overlaps as holes; this is one static instance
# (FILL 1, weight 600 as a filled MaterialSymbol has, GRAD 0, optical size 20, most widget icons' size) with the
# overlaps merged.
# Re-run after the ttf-material-symbols-variable package updates. Needs fontTools and skia-pathops, in a venv here.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="/usr/share/fonts/ttf-material-symbols-variable/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf"
DEST="$REPO/dots/.config/quickshell/ii/modules/caelestia/assets/material-symbols-filled"
VENV="${XDG_CACHE_HOME:-$HOME/.cache}/caelestia4/fontvenv"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP:?}"' EXIT

[[ -x "$VENV/bin/python" ]] || { python3 -m venv "$VENV" && "$VENV/bin/pip" install -q fonttools skia-pathops; }
"$VENV/bin/fonttools" varLib.instancer "$SRC" FILL=1 wght=600 GRAD=0 opsz=20 --remove-overlaps -o "$TMP/filled.ttf"
"$VENV/bin/python" - "$TMP/filled.ttf" "$DEST/MaterialSymbolsRoundedFilled.ttf" <<'EOF'
import sys
from fontTools.ttLib import TTFont
font = TTFont(sys.argv[1])
family = "Material Symbols Rounded Filled"  # its own family: never taken for the variable font
names = {1: family, 2: "Regular", 4: family, 6: "MaterialSymbolsRoundedFilled-Regular", 16: family, 17: "Regular"}
for record in font["name"].names:
    if record.nameID in names:
        record.string = names[record.nameID]
font["OS/2"].usWeightClass = 400
font.save(sys.argv[2])
EOF
echo "wrote $DEST/MaterialSymbolsRoundedFilled.ttf"

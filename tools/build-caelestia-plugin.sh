#!/usr/bin/env bash
# Build ONLY the Caelestia C++ QML plugin from the vendored subtree and install it
# user-locally (~/.local/lib/qt6/qml/Caelestia). Nothing is installed system-wide.
# The import path is added only in the Hyprland session (QML_IMPORT_PATH in env.lua).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/third_party/caelestia-shell"
BUILD="$REPO_ROOT/build/caelestia-plugin"
PREFIX="${PREFIX:-$HOME/.local}"

# Vendored: caelestia-dots/shell main 4b1dae84 (v2.5.0+50, 2026-10-25); before that 2e1c51fa (v2.5.0+48), 29fcf69a (v2.5.0+39), 21a75375 (v2.5.0+20); originally v2.5.0 -> d999d487 (docs/dev/phase1.md)
VERSION="2.5.0"
GIT_REVISION="4b1dae84b"

# caelestia4: our translations (tools/i18n/caelestia-<lang>.po) go into the plugin's catalogs (trs/<lang>.po)
TRS="$SRC/plugin/src/Caelestia/I18n/trs"
mkdir -p "$TRS"
for po in "$REPO_ROOT"/tools/i18n/caelestia-*.po; do
  [[ -e "$po" ]] || continue
  lang=$(basename "$po" .po); lang=${lang#caelestia-}
  cp "$po" "$TRS/$lang.po"
done

cmake -S "$SRC" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_MODULES=plugin \
  -DVERSION="$VERSION" \
  -DGIT_REVISION="$GIT_REVISION" \
  -DDISTRIBUTOR="caelestia_4" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DINSTALL_QMLDIR="lib/qt6/qml"

cmake --build "$BUILD"
cmake --install "$BUILD"

# caelestia4: what this build was made from, for Nexus > Plugins (the plugin uses Qt's private API: a Qt minor update
# needs a rebuild, and the .so files don't say which Qt they were built with)
printf '{"qt": "%s", "revision": "%s", "version": "%s", "built": "%s"}\n' \
  "$(/usr/lib/qt6/bin/qtpaths6 --qt-version 2>/dev/null || pacman -Q qt6-base | cut -d' ' -f2 | cut -d- -f1)" "$GIT_REVISION" "$VERSION" \
  "$(date -Iseconds)" > "$PREFIX/lib/qt6/qml/Caelestia/caelestia4-build.json"

echo "Installed Caelestia QML plugin to $PREFIX/lib/qt6/qml/Caelestia"

#!/usr/bin/env bash
# Build ONLY the Caelestia C++ QML plugin from the vendored subtree and install it
# user-locally (~/.local/lib/qt6/qml/Caelestia). Nothing is installed system-wide.
# The import path is added only in the Hyprland session (QML_IMPORT_PATH in env.lua).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/third_party/caelestia-shell"
BUILD="$REPO_ROOT/build/caelestia-plugin"
PREFIX="${PREFIX:-$HOME/.local}"

# Vendored tag v2.5.0 -> commit d999d487 (see docs/phase1.md)
VERSION="2.5.0"
GIT_REVISION="d999d4878"

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

echo "Installed Caelestia QML plugin to $PREFIX/lib/qt6/qml/Caelestia"

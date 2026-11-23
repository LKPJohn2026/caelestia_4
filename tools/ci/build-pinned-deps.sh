#!/usr/bin/env bash
# The two libraries the QML job needs that Arch's official repos don't have, built from pinned upstream sources (not
# from the AUR) into a staging root that root then copies to / (.github/workflows/qml.yml caches that root):
#   libcava   the Caelestia plugin's audio visualiser (pkg-config libcava). Arch's cava package ships only the
#             program: no libcava.so and no .pc. Upstream fork LukashonakV/cava, the tag below's commit, fetched by its
#             id and checked after the fetch (as M3Shapes). Not GitHub's tarball of the tag: that archive is made on
#             the fly, and GitHub has changed how (2023, gzip), which changed every such tarball's checksum. Built as
#             the lib only, with only the PipeWire input (what the plugin uses), no font, no sanitizers.
#   M3Shapes  the QML module the Caelestia family's shapes import (users get it from qt6-m3shapes-git). The commit
#             below, fetched by its id and checked after the fetch.
# Run as a normal user (the sources are built, never run, and root only copies the result).
# Usage: tools/ci/build-pinned-deps.sh STAGE
set -euo pipefail

LIBCAVA_TAG=1.0.0 # its commit:
LIBCAVA_COMMIT=f03278ef9e5e7948fb206453d2f02758f8db216c
M3SHAPES_COMMIT=8a6fe8961749887d677700b6508e0c9249968b7e # r50, the revision the shell is used with

[[ $# -eq 1 && -n $1 ]] || { echo "usage: $0 STAGE" >&2; exit 2; }
[[ $(id -u) -ne 0 ]] || { echo "build-pinned-deps: run it as a normal user, not root" >&2; exit 2; }
mkdir -p "$1"
stage=$(cd "$1" && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

echo "== libcava $LIBCAVA_TAG ($LIBCAVA_COMMIT)"
git init -q "$work/cava"
git -C "$work/cava" fetch -q --depth 1 https://github.com/LukashonakV/cava.git "$LIBCAVA_COMMIT"
git -C "$work/cava" -c advice.detachedHead=false checkout -q FETCH_HEAD
got=$(git -C "$work/cava" rev-parse HEAD)
[[ $got == "$LIBCAVA_COMMIT" ]] || { echo "libcava: got commit $got, not $LIBCAVA_COMMIT" >&2; exit 1; }
off=()
for o in input_alsa input_portaudio input_pulse input_sndio input_oss input_jack output_sdl output_sdl_glsl output_ncurses \
         asan tsan ubsan; do off+=("-D$o=disabled"); done
(cd "$work/cava" &&
  meson setup build --prefix=/usr --libdir=lib --buildtype=release -Dcava_font=false -Dinput_pipewire=enabled "${off[@]}" &&
  meson compile -C build &&
  DESTDIR="$stage" meson install -C build --no-rebuild)

echo "== M3Shapes $M3SHAPES_COMMIT"
git init -q "$work/m3shapes"
git -C "$work/m3shapes" fetch -q --depth 1 https://github.com/soramanew/m3shapes.git "$M3SHAPES_COMMIT"
git -C "$work/m3shapes" -c advice.detachedHead=false checkout -q FETCH_HEAD
got=$(git -C "$work/m3shapes" rev-parse HEAD)
[[ $got == "$M3SHAPES_COMMIT" ]] || { echo "M3Shapes: got commit $got, not $M3SHAPES_COMMIT" >&2; exit 1; }
cmake -S "$work/m3shapes" -B "$work/m3shapes/build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib
cmake --build "$work/m3shapes/build"
DESTDIR="$stage" cmake --install "$work/m3shapes/build"

[[ -e $stage/usr/lib/pkgconfig/libcava.pc && -e $stage/usr/lib/qt6/qml/M3Shapes/qmldir ]] ||
  { echo "build-pinned-deps: libcava.pc or M3Shapes/qmldir is missing from $stage" >&2; exit 1; }
echo "build-pinned-deps: OK ($stage)"

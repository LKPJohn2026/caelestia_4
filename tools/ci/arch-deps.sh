#!/usr/bin/env bash
# The QML job's packages (.github/workflows/qml.yml), in its archlinux:base-devel container, as root. Not for a real
# machine: it upgrades the whole system, so it refuses to run outside a GitHub Actions container.
#   - every pacman command is tried 3 times, 30 s apart (mirrors fail now and then); pacman 7's download sandbox is
#     turned off only if this kernel or container can't give it Landlock
#   - Quickshell's depends and makedepends, read from packaging/caelestia4-quickshell/PKGBUILD (not copied here)
#   - the Caelestia plugin's (tools/build-caelestia-plugin.sh and its CMake: libqalculate, aubio, lm_sensors, cmake,
#     ninja, pkgconf), the pinned libcava and M3Shapes builds' (tools/ci/build-pinned-deps.sh: meson, fftw, iniparser)
#     and the tests' (tools/ci-qml.sh: sway as a headless compositor, dbus, rsync)
#   - the user "builder" (makepkg refuses root; sway and the shell run as a normal user), owning the checkout
# Usage: tools/ci/arch-deps.sh
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 2

[[ ${GITHUB_ACTIONS:-} == true && $(id -u) -eq 0 && -f /etc/arch-release ]] &&
  [[ -e /.dockerenv || -e /run/.containerenv ]] ||
  { echo "arch-deps: only for the CI container (GitHub Actions, root, Arch, in a container)" >&2; exit 2; }

nosandbox=()
log=$(mktemp)
trap 'rm -f "$log"' EXIT
pm() { # pm ARGS...: pacman, 3 tries; without its sandbox when Landlock is missing
  local attempt
  for attempt in 1 2 3; do
    if pacman --noconfirm "${nosandbox[@]}" "$@" 2>&1 | tee "$log"; then return 0; fi # pipefail: pacman's status
    if [[ ${#nosandbox[@]} -eq 0 ]] && grep -qiE 'landlock|sandbox' "$log"; then
      echo "::warning::pacman's sandbox is not available here, running it with --disable-sandbox"
      nosandbox=(--disable-sandbox); continue
    fi
    echo "::warning::pacman $* failed (attempt $attempt of 3)"
    [[ $attempt -lt 3 ]] && sleep 30
  done
  return 1
}

mapfile -t qs_deps < <(
  # shellcheck disable=SC1091,SC2154 # the PKGBUILD sets depends and makedepends
  source packaging/caelestia4-quickshell/PKGBUILD && printf '%s\n' "${depends[@]}" "${makedepends[@]}")
[[ ${#qs_deps[@]} -gt 0 ]] || { echo "arch-deps: no depends read from the PKGBUILD" >&2; exit 1; }
extra=(cmake ninja pkgconf libqalculate aubio lm_sensors # the plugin
       fish gettext                                      # its translations (scripts/trs.fish runs msgfmt)
       meson fftw iniparser                              # libcava (tools/ci/build-pinned-deps.sh)
       sway dbus rsync git libcap)                       # the tests (libcap: setcap, below)
echo "installing: ${qs_deps[*]} ${extra[*]}"
pm -Syu --needed "${qs_deps[@]}" "${extra[@]}"

# Arch rolls: what this run had
pacman -Q qt6-base qt6-declarative qt6-shadertools sway
pacman -Qq | grep '^wlroots' | xargs -r pacman -Q

# sway is installed with cap_sys_nice, which the runner's container may not grant: exec then fails with "Operation
# not permitted". The test compositor needs no realtime priority, so the capability goes (only in this container)
if command -v setcap >/dev/null && [[ -n $(getcap /usr/bin/sway 2>/dev/null) ]]; then
  setcap -r /usr/bin/sway && echo "arch-deps: dropped sway's file capability"
fi

id builder >/dev/null 2>&1 || useradd -m builder
chown -R builder: "$PWD"
echo "arch-deps: OK"

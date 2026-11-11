#!/usr/bin/env bash
# caelestia_4 installer: everything from a fresh Arch / CachyOS to the uwsm Hyprland session, in one script.
#
#   git clone --recursive https://github.com/LKPJohn2026/caelestia_4.git && cd caelestia_4 && ./install.sh
# or, without cloning first (it clones into ~/.local/share/caelestia_4 and runs from there):
#   bash <(curl -fsSL https://raw.githubusercontent.com/LKPJohn2026/caelestia_4/main/install.sh)
#
# Run it again to update after a `git pull`: every step skips what is already done.
# What it does, in order (each step that uses sudo says so before it runs):
#   1. checks: Arch-based, systemd, not root, a git clone with its submodule, ~/.config as the config folder
#   2. system upgrade, base-devel and git (sudo pacman -Syu: the packages below are built against the current Qt)
#   3. an AUR helper: yay or paru, or yay-bin from the AUR if you agree
#   4. finds the packages that conflict with this fork's (end-4's Quickshell, another caelestia-cli, PulseAudio...)
#      and asks to replace them; pacman replaces each in the transaction that installs what replaces it
#   5. the dependencies, read from the PKGBUILDs in sdata/dist-arch and packaging/: repo ones with pacman, AUR ones
#      with the helper, all marked as dependencies (`./install.sh --list-deps` prints them)
#   6. builds and installs end-4's metapackages and this fork's packages (Quickshell pinned for the Qt you have,
#      qtengine, Wormhole, Atlas, caelestia-cli), skipping the ones already at their version; the ones using Qt's
#      private API again when Qt moved to a new minor release
#   7. turns on NetworkManager and Bluetooth (sudo systemctl enable --now), unless another network service runs
#   8. fonts no package has (tools/fonts-install.sh, sudo)
#   9. the configs, the Caelestia plugin, end-4's Python venv and the uwsm session (tools/install-main.sh, no sudo;
#      backs up what it replaces to ~/.local/state/caelestia4/backup-*)
#  10. the login screen: with none set up, greetd + ReGreet if you agree (tools/greetd-setup.sh); with one (SDDM,
#      GDM...), it stays and you pick "Hyprland (uwsm-managed)" on it
# It never touches the boot loader, disk encryption, sudoers or your files in ~/.config/hypr/custom.
set -uo pipefail

REPO_URL="${C4_REPO_URL:-https://github.com/LKPJohn2026/caelestia_4.git}"
BRANCH="${C4_BRANCH:-main}"
CLONE_DIR="${C4_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/caelestia_4}"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]
  -y, --yes        answer yes to every question (other network services are never turned off)
  -n, --dry-run    print what would run, change nothing
      --no-login   don't set up a login screen
      --rebuild    build this repo's packages and the Caelestia plugin again even when they are at their version
      --list-deps  print the packages it would install (repo and AUR) and exit
  -h, --help       this help
Environment: C4_DIR (where the one-line install clones, default ~/.local/share/caelestia_4), C4_REPO_URL, C4_BRANCH.
EOF
}

YES=false DRY=false LOGIN=true REBUILD=false LISTDEPS=false
args=("$@")
while (($#)); do
  case "$1" in
    -y | --yes) YES=true ;;
    -n | --dry-run) DRY=true ;;
    --no-login) LOGIN=false ;;
    --rebuild) REBUILD=true ;;
    --list-deps) LISTDEPS=true ;;
    -h | --help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

bold=$'\e[1m' blue=$'\e[1;34m' yellow=$'\e[33m' red=$'\e[31m' rst=$'\e[0m'
[[ -t 1 ]] || bold='' blue='' yellow='' red='' rst=''
step() { printf '\n%s==> %s%s\n' "$blue" "$*" "$rst"; }
say() { printf '%s::%s %s\n' "$bold" "$rst" "$*"; }
warn() { printf '%s!!%s %s\n' "$yellow" "$rst" "$*"; WARNINGS+=("$*"); }
die() { printf '%sxx%s %s\n' "$red" "$rst" "$*" >&2; exit 1; }
WARNINGS=()

# run <command...>: print it, then run it (not in a dry run)
run() {
  local cmd; printf -v cmd '%q ' "$@"
  printf '   %s$ %s%s\n' "$bold" "${cmd% }" "$rst"
  $DRY && return 0
  "$@"
}
# ask <question> <default y|n>: true for yes. --yes takes the default; without a terminal to ask on, too.
ask() {
  local q="$1" def="$2" a
  if $YES || $DRY || ! { true </dev/tty; } 2>/dev/null; then
    say "$q [default: $def]"; [[ "$def" == y ]]; return
  fi
  while true; do
    read -r -p "$bold??$rst $q [$([[ $def == y ]] && echo Y/n || echo y/N)] " a </dev/tty || a=""
    case "${a,,}" in
      "") [[ "$def" == y ]]; return ;;
      y | yes) return 0 ;;
      n | no) return 1 ;;
    esac
  done
}

# ---- 0. the one-line install: no clone around this script yet ----
SELF="$(readlink -f "${BASH_SOURCE[0]:-}" 2>/dev/null || true)"
REPO="$(dirname "$SELF")"
# before anything is installed or cloned (step 1 checks the rest)
command -v pacman >/dev/null || die "this is for Arch-based systems (pacman not found)"
# Quickshell, qtengine, Wormhole, Atlas and MicroTeX are built for x86_64 only (arch=(x86_64) in their PKGBUILDs)
[[ "$(uname -m)" == x86_64 ]] || die "this is for x86_64 only ($(uname -m) here): several packages built here declare arch=(x86_64)"
if [[ ! -f "$REPO/tools/install-main.sh" ]]; then
  [[ "$(id -u)" -ne 0 ]] || die "run it as your user, not root (it asks for sudo when it needs it)"
  # -Syu, not -S: on a system whose package lists are old, -S asks the mirrors for versions they no longer have
  command -v git >/dev/null || { say "git is needed to fetch caelestia_4"; run sudo pacman -Syu --needed --noconfirm git || die "couldn't install git"; }
  if [[ -d "$CLONE_DIR/.git" ]]; then
    step "updating $CLONE_DIR"
    run git -C "$CLONE_DIR" fetch origin "$BRANCH" || die "couldn't reach $(git -C "$CLONE_DIR" remote get-url origin 2>/dev/null) (network?)"
    [[ -z "$(git -C "$CLONE_DIR" status --porcelain --untracked-files=no --ignore-submodules=all)" ]] \
      || die "$CLONE_DIR has changes of its own: commit or stash them, then run $CLONE_DIR/install.sh"
    [[ "$(git -C "$CLONE_DIR" symbolic-ref -q --short HEAD)" == "$BRANCH" ]] || run git -C "$CLONE_DIR" checkout -q "$BRANCH" \
      || die "couldn't switch $CLONE_DIR to the branch $BRANCH"
    run git -C "$CLONE_DIR" merge --ff-only "origin/$BRANCH" \
      || die "$CLONE_DIR can't fast-forward to origin/$BRANCH (commits of your own, or the history was rewritten): see \"If git pull says the histories diverged\" in docs/install.md"
    run git -C "$CLONE_DIR" submodule update --init --recursive || die "couldn't fetch the submodules"
  else
    step "cloning caelestia_4 into $CLONE_DIR"
    [[ ! -e "$CLONE_DIR" ]] || die "$CLONE_DIR exists and isn't a clone: move it away or set C4_DIR"
    run mkdir -p "$(dirname "$CLONE_DIR")"
    run git clone --recursive --branch "$BRANCH" "$REPO_URL" "$CLONE_DIR" || die "couldn't clone $REPO_URL"
  fi
  $DRY && { say "dry run: would continue with $CLONE_DIR/install.sh"; exit 0; }
  exec "$CLONE_DIR/install.sh" "${args[@]}"
fi
cd "$REPO" || die "can't enter $REPO"

# ---- the dependencies, from the PKGBUILDs ----
# end-4's metapackages this fork uses (not illogical-impulse-quickshell-git: packaging/caelestia4-quickshell replaces it)
META=(audio backlight basic fonts-themes kde portal python screencapture toolkit widgets hyprland caelestia4 microtex-git bibata-modern-classic-bin)
META=("${META[@]/#/sdata/dist-arch/illogical-impulse-}")
# this fork's packages, Quickshell first (the others build against it or run in it)
PACKAGES=(quickshell qtengine wormhole atlas cli)
PACKAGES=("${PACKAGES[@]/#/packaging/caelestia4-}")
BUILT=("${META[@]}" "${PACKAGES[@]}")

# pkgfield <dir> <expr>: an expression over a PKGBUILD's variables, evaluated in a subshell (nothing leaks out)
pkgfield() { (cd "$1" && unset depends makedepends conflicts pkgname pkgver pkgrel epoch && source ./PKGBUILD >/dev/null 2>&1 && eval "$2"); }
pkgname_of() { pkgfield "$1" 'echo "$pkgname"'; }
pkgver_of() { pkgfield "$1" 'echo "${epoch:+$epoch:}$pkgver-$pkgrel"'; }
# every depends and makedepends, without version constraints, minus the packages built here
all_deps() {
  local d own
  own=$(for d in "${BUILT[@]}"; do pkgname_of "$d"; done)
  for d in "${BUILT[@]}"; do pkgfield "$d" 'printf "%s\n" "${depends[@]}" "${makedepends[@]}"'; done |
    sed -E 's/[<>=].*$//' | sort -u | command grep -vxF -f <(printf '%s\n' "$own") | command grep -v '^$'
}
REPO_DEPS=() AUR_DEPS=()
classify_deps() {
  local p
  for p in $(all_deps); do
    if pacman -Sp --print-format '%n' -- "$p" >/dev/null 2>&1; then REPO_DEPS+=("$p"); else AUR_DEPS+=("$p"); fi
  done
}

if $LISTDEPS; then
  command -v pacman >/dev/null || die "pacman is needed to tell repo packages from AUR ones"
  classify_deps
  echo "# from the repos (pacman):"; printf '%s\n' "${REPO_DEPS[@]}"
  echo "# from the AUR:"; printf '%s\n' "${AUR_DEPS[@]}"
  echo "# built from this repository:"; for d in "${BUILT[@]}"; do echo "$(pkgname_of "$d")  ($d)"; done
  exit 0
fi

# ---- the log ----
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
if ! $DRY; then
  LOG="$STATE/caelestia4/install-$(date +%Y%m%d-%H%M%S).log"
  mkdir -p "$(dirname "$LOG")" && exec > >(tee -a "$LOG") 2>&1
fi

# ---- 1. checks ----
step "1/10 checking this system"
[[ "$(id -u)" -ne 0 ]] || die "run it as your user, not root (it asks for sudo when it needs it)"
# shellcheck disable=SC1091
os_id=$(. /etc/os-release 2>/dev/null; echo "${ID:-} ${ID_LIKE:-}")
[[ " $os_id " == *" arch "* || -f /etc/arch-release ]] || die "this is for Arch-based systems (/etc/os-release: $os_id)"
[[ -d /run/systemd/system ]] || die "systemd isn't running (it's needed for uwsm and the shell's units)"
command -v sudo >/dev/null || die "sudo is needed (pacman -S sudo, and add yourself to wheel)"
# shellcheck source=tools/lib-require-dot-config.sh
source "$REPO/tools/lib-require-dot-config.sh"
systemctl --user show-environment >/dev/null 2>&1 \
  || die "your user's systemd isn't reachable: run this from your own login (a TTY or a desktop), not su or sudo -u"
free_gb=$(df -Pk "$REPO" | awk 'NR==2 {print int($4 / 1048576)}')
((free_gb >= 8)) || warn "only ${free_gb} GB free next to the clone: building the packages needs about 8 GB"
git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || die "$REPO isn't a git clone (a zip won't work): use git clone --recursive"
# Only the ones never fetched: a submodule at another version (work of your own on it, or a pull that moved it) is
# install-main.sh's to handle, which keeps your commits on top of the recorded version
mapfile -t uninit < <(git -C "$REPO" submodule status --recursive 2>/dev/null | awk '/^-/ {print $2}')
if ((${#uninit[@]})); then
  run git -C "$REPO" submodule update --init --recursive -- "${uninit[@]}" || die "couldn't fetch the submodules (network?)"
fi
say "$(. /etc/os-release; echo "${PRETTY_NAME:-Arch}"), $(nproc) CPUs, ${free_gb} GB free, repo at $REPO"

# sudo once, kept alive until the end
if ! $DRY; then
  say "some steps need sudo; asking for it once"
  sudo -v || die "sudo failed"
  while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done &
  SUDO_KEEPALIVE=$!
  trap 'kill $SUDO_KEEPALIVE 2>/dev/null' EXIT
fi
NOCONFIRM=(--noconfirm)

# ---- 2. system upgrade ----
step "2/10 system upgrade (sudo pacman -Syu)"
qt_minor() { pacman -Q qt6-base 2>/dev/null | sed -E 's/^\S+ ([0-9]+\.[0-9]+).*/\1/'; }
qt_before=$(qt_minor)
run sudo pacman -Syu --needed "${NOCONFIRM[@]}" base-devel git || die "the system upgrade failed: fix it, then run this again"
# Quickshell, qtengine, Wormhole, Atlas and the Caelestia plugin use Qt's private API, stable only within one Qt minor
# release: built again when the upgrade moved Qt, or when Quickshell was built for another Qt already (system.py tells,
# the same check Nexus > Updates shows; tools/install-main.sh checks the plugin the same way)
QT_REBUILD=$REBUILD
if [[ -n "$qt_before" && "$qt_before" != "$(qt_minor)" ]]; then
  QT_REBUILD=true; say "Qt moved from $qt_before to $(qt_minor): Quickshell and the Caelestia plugin are built again"
elif python3 - "$REPO/dots/.config/quickshell/ii/modules/caelestia/utils/scripts/system.py" 2>/dev/null <<'PY'
import json, subprocess, sys
data = json.loads(subprocess.run([sys.executable, sys.argv[1], "components"], capture_output=True, text=True).stdout)
sys.exit(0 if any(c["name"] == "Quickshell" and c.get("needsRebuild") for c in data["components"]) else 1)
PY
then
  QT_REBUILD=true; say "Quickshell was built for another Qt: it is built again (install-main.sh checks the Caelestia plugin)"
fi
QT_LINKED=(caelestia4-quickshell caelestia4-qtengine caelestia4-wormhole caelestia4-atlas)

# ---- 3. AUR helper ----
step "3/10 AUR helper"
AUR=""
for h in yay paru; do command -v "$h" >/dev/null && { AUR=$h; break; }; done
if [[ -z "$AUR" ]]; then
  if ask "No AUR helper found. Build yay-bin from the AUR (https://aur.archlinux.org/packages/yay-bin)?" y; then
    if $DRY; then
      run git clone --depth 1 https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
      run makepkg -s "${NOCONFIRM[@]}"
      run sudo pacman -U "${NOCONFIRM[@]}" /tmp/yay-bin/yay-bin-VERSION-x86_64.pkg.tar.zst
    else
      tmp=$(mktemp -d) || die "mktemp failed"
      run git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" || die "couldn't fetch yay-bin"
      # makepkg -s, then only yay-bin itself: -si would also install the yay-bin-debug that Arch's makepkg.conf makes
      (cd "$tmp/yay-bin" && run makepkg -s "${NOCONFIRM[@]}" && run sudo pacman -U "${NOCONFIRM[@]}" \
        "$(makepkg --packagelist | command grep -v -- '-debug-' | head -1)") || die "couldn't build yay-bin"
      rm -r -- "$tmp"
    fi
    AUR=yay
  else
    die "an AUR helper is needed (some dependencies are only in the AUR): install yay or paru, then run this again"
  fi
fi
say "using $AUR"
# The helper's menus answered: no diff review, no clean build prompts. No --removemake: it ends with pacman -Rsu of the
# build tools, and -s also takes every --asdeps package nothing installed needs yet, which until step 6 is all of them
# (a fresh install lost ninja that way, then the caelestia4 metapackage couldn't build)
aur_install() {
  case "$AUR" in
    yay) run yay -S --needed --asdeps "${NOCONFIRM[@]}" "${ASK[@]}" --answerclean None --answerdiff None "$@" ;;
    paru) run paru -S --needed --asdeps "${NOCONFIRM[@]}" "${ASK[@]}" --skipreview "$@" ;;
  esac
}

# ---- 4. conflicts ----
step "4/10 packages that conflict with this fork's"
classify_deps
# fieldof <field>: a pacman / AUR helper -i field, its wrapped lines too (LC_ALL=C: the labels are translated)
fieldof() { awk -v f="$1" 'index($0, f) == 1 { on = 1; sub(/^[^:]*: */, ""); print; next } /^[^ ]/ { on = 0 } on'; }
# installed_conflicts <spec...>: the installed packages matching conflict specs (a name, a name it provides, or a
# version range like caelestia-shell<2.4.0, which pacman -T checks)
installed_conflicts() {
  local c
  for c in "$@"; do
    [[ -n "$c" && "$c" != None ]] && pacman -T "$c" >/dev/null 2>&1 && pacman -Qq "${c%%[<>=]*}" 2>/dev/null
  done
}
# What the packages about to be installed conflict with: this repo's PKGBUILDs (another Quickshell, caelestia-cli...),
# the repo dependencies (pipewire-pulse with pulseaudio, go-yq with yq...) and the AUR ones (darkly-bin with darkly...).
# They are not removed on their own: pacman's --ask=4 answers yes to "remove the conflicting package?" inside the
# transaction that installs the replacement, so a failed install removes nothing, and pacman refuses (removing nothing)
# when something else still needs the old package by a name the new one doesn't provide.
ASK=(--ask=4)
c=()
for d in "${BUILT[@]}"; do
  pacman -Qq "$(pkgname_of "$d")" >/dev/null 2>&1 && continue # already ours: whatever it replaced is gone
  mapfile -t -O "${#c[@]}" c < <(pkgfield "$d" 'printf "%s\n" "${conflicts[@]}"')
done
missing_repo=() missing_aur=()
for p in "${REPO_DEPS[@]}"; do pacman -T "$p" >/dev/null 2>&1 || missing_repo+=("$p"); done
for p in "${AUR_DEPS[@]}"; do pacman -T "$p" >/dev/null 2>&1 || missing_aur+=("$p"); done
((${#missing_repo[@]})) && mapfile -t -O "${#c[@]}" c < <(LC_ALL=C pacman -Si "${missing_repo[@]}" 2>/dev/null | fieldof 'Conflicts With' | tr -s ' ' '\n')
if ((${#missing_aur[@]})); then
  if command -v "$AUR" >/dev/null; then
    mapfile -t -O "${#c[@]}" c < <(LC_ALL=C "$AUR" -Si "${missing_aur[@]}" 2>/dev/null | fieldof 'Conflicts With' | tr -s ' ' '\n')
  else
    say "(dry run: what the AUR packages conflict with is known once $AUR is installed)"
  fi
fi
mapfile -t confl < <(installed_conflicts "${c[@]}" | sort -u)
# PulseAudio's modules need pulseaudio=<its exact version>, so pacman can't replace pulseaudio while they're there:
# they go first (pacman -R, which checks nothing else needs them). From pulseaudio's Required By, not by name:
# pulseaudio-qt is a Qt library KDE apps use, not part of it.
pulse_mods=()
if pacman -Qq pulseaudio >/dev/null 2>&1; then
  mapfile -t pulse_mods < <(LC_ALL=C pacman -Qi pulseaudio | fieldof 'Required By' | tr -s ' ' '\n' |
    command grep -xE 'pulseaudio-.*|manjaro-pulse' | command grep -vx pulseaudio-qt)
fi
if ((${#confl[@]} + ${#pulse_mods[@]})); then
  say "installed, and replaced by this fork's packages: ${confl[*]} ${pulse_mods[*]}"
  ask "Replace them (each when what replaces it is installed)?" y \
    || die "they can't stay next to this fork's packages: nothing was changed by this step"
else
  say "none"
fi

# ---- 5. dependencies ----
step "5/10 dependencies (${#REPO_DEPS[@]} from the repos, ${#AUR_DEPS[@]} from the AUR)"
if ((${#pulse_mods[@]})); then
  run sudo pacman -R "${NOCONFIRM[@]}" "${pulse_mods[@]}" || die "couldn't remove PulseAudio's modules ${pulse_mods[*]} (something else needs them, see above)"
fi
if ((${#missing_repo[@]})); then
  run sudo pacman -S --needed --asdeps "${NOCONFIRM[@]}" "${ASK[@]}" "${missing_repo[@]}" \
    || die "installing the repo packages failed (a package that conflicts with one of them is still needed by another, see above)"
else say "repo packages: all there"; fi
# import_aur_keys <pkg...>: the PGP keys these AUR packages' sources are signed with (validpgpkeys in their .SRCINFO),
# from the first keyserver that answers. Left to makepkg, the key comes from gpg's default keyserver only
# (keyserver.ubuntu.com), and when that one is down the whole step fails.
import_aur_keys() {
  local q='' p base k ks bases=() keys=()
  for p in "$@"; do q+="&arg[]=$p"; done
  mapfile -t bases < <(curl -fsS --max-time 30 "https://aur.archlinux.org/rpc/v5/info?${q#&}" 2>/dev/null |
    command grep -o '"PackageBase":"[^"]*"' | cut -d'"' -f4 | sort -u)
  for base in "${bases[@]}"; do
    mapfile -t -O "${#keys[@]}" keys < <(curl -fsS --max-time 30 "https://aur.archlinux.org/cgit/aur.git/plain/.SRCINFO?h=$base" 2>/dev/null |
      awk '$1 == "validpgpkeys" { print $3 }')
  done
  for k in $(printf '%s\n' "${keys[@]}" | sort -u); do
    gpg --batch --list-keys "$k" >/dev/null 2>&1 && continue
    if $DRY; then say "would fetch the PGP key $k (keys.openpgp.org, else keyserver.ubuntu.com)"; continue; fi
    for ks in hkps://keys.openpgp.org hkps://keyserver.ubuntu.com hkps://pgp.mit.edu; do
      timeout 60 gpg --batch --keyserver "$ks" --recv-keys "$k" >/dev/null 2>&1 && { say "PGP key $k from ${ks#hkps://}"; continue 2; }
    done
    warn "couldn't fetch the PGP key $k from any keyserver: the AUR package signed with it may fail to build"
  done
}
if ((${#missing_aur[@]})); then
  say "from the AUR (built on this machine): ${missing_aur[*]}"
  import_aur_keys "${missing_aur[@]}"
  aur_install "${missing_aur[@]}" || die "building the AUR packages failed (network, a PKGBUILD changed upstream, or a conflict, see above): run this again"
else say "AUR packages: all there"; fi
# Until the metapackages of step 6 are installed, nothing depends on the packages above: anything that cleans orphans
# in between (an AUR helper, a hook) can take them away again. Put back what's gone before building on them.
missing_repo=()
for p in "${REPO_DEPS[@]}"; do pacman -T "$p" >/dev/null 2>&1 || missing_repo+=("$p"); done
if ((${#missing_repo[@]})) && ! $DRY; then
  say "removed again after this step, installing them back: ${missing_repo[*]}"
  run sudo pacman -S --needed --asdeps "${NOCONFIRM[@]}" "${ASK[@]}" "${missing_repo[@]}" || die "installing the repo packages failed"
fi

# ---- 6. build this repo's packages ----
step "6/10 building end-4's metapackages and this fork's packages"
build_install() { # build_install <dir>: makepkg there, then pacman -U; skipped when already at its version
  local d="$1" name ver have
  name=$(pkgname_of "$d"); ver=$(pkgver_of "$d")
  have=$(pacman -Q "$name" 2>/dev/null | awk '{print $2}')
  local again=$REBUILD
  $QT_REBUILD && [[ " ${QT_LINKED[*]} " == *" $name "* ]] && again=true
  if [[ "$have" == "$ver" ]] && ! $again; then
    say "$name $have: up to date"; return 0
  fi
  say "$name: ${have:-not installed} -> $ver"
  (cd "$d" && run makepkg -Cf "${NOCONFIRM[@]}") || return 1
  if $DRY; then
    run sudo pacman -U "${NOCONFIRM[@]}" "${ASK[@]}" "$d/$name-$ver-*.pkg.tar.zst"
    return 0
  fi
  # --packagelist also names a -debug package, which makepkg doesn't make for every package (arch=any): only what was
  # built, and no debug symbols
  files=()
  while IFS= read -r f; do [[ -f "$f" && "$(basename "$f")" != *-debug-* ]] && files+=("$f"); done < <(cd "$d" && makepkg --packagelist)
  ((${#files[@]})) || { warn "makepkg made no package in $d"; return 1; }
  # not --needed: a rebuild has the version that's installed, and --needed would skip it. --ask=4: see step 4
  run sudo pacman -U "${NOCONFIRM[@]}" "${ASK[@]}" "${files[@]}" || return 1
  # explicitly installed: a cleanup of orphans must not take the shell away
  run sudo pacman -D --asexplicit "$name" >/dev/null
}
for d in "${BUILT[@]}"; do build_install "$d" || die "building $d failed (see above; the log is $LOG)"; done

# ---- 7. services ----
step "7/10 system services"
# enabled_units <ERE>: enabled system units whose name matches (from the .wants links, which also hold template
# instances like dhcpcd@eth0 that `systemctl is-enabled dhcpcd` doesn't see; a link left by a removed package isn't)
enabled_units() {
  local u
  find /etc/systemd/system -path '*.wants/*' -name '*.service' -printf '%f\n' 2>/dev/null | sed 's/\.service$//' |
    command grep -E "$1" | sort -u | while read -r u; do
      [[ "$(systemctl is-enabled "$u.service" 2>/dev/null)" == enabled ]] && echo "$u"
    done
}
other_net=()
for s in systemd-networkd iwd dhcpcd connman; do
  [[ "$(systemctl is-enabled "$s.service" 2>/dev/null)" == enabled ]] && other_net+=("$s")
done
# and per-interface ones (dhcpcd@eth0, netctl profiles, wpa_supplicant@wlan0 without NetworkManager)
mapfile -t -O "${#other_net[@]}" other_net < <(enabled_units '^(dhcpcd@|netctl|wpa_supplicant@|systemd-networkd@)')
if [[ "$(systemctl is-enabled NetworkManager.service 2>/dev/null)" == enabled ]]; then
  say "NetworkManager: on"
elif ((${#other_net[@]})); then
  warn "${other_net[*]} manages the network here, so NetworkManager stays off: Nexus and the bar show no networks. To switch: sudo systemctl disable --now ${other_net[*]} && sudo systemctl enable --now NetworkManager"
else
  run sudo systemctl enable --now NetworkManager.service || warn "couldn't start NetworkManager"
fi
[[ "$(systemctl is-enabled bluetooth.service 2>/dev/null)" == enabled ]] && say "Bluetooth: on" \
  || run sudo systemctl enable --now bluetooth.service || warn "couldn't start Bluetooth (no adapter?)"

# ---- 8. fonts ----
step "8/10 fonts"
run "$REPO/tools/fonts-install.sh" || warn "the fonts weren't installed: run tools/fonts-install.sh later"

# ---- 9. configs and session ----
step "9/10 configs, the Caelestia plugin and the uwsm session (tools/install-main.sh)"
$QT_REBUILD && export C4_REBUILD_PLUGIN=1
run "$REPO/tools/install-main.sh" || die "tools/install-main.sh failed (see above)"

# ---- 10. login screen ----
step "10/10 login screen"
dm=$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" .service 2>/dev/null)
[[ "$dm" == display-manager ]] && dm=""
# login managers enabled without that alias (ly@tty2), and a getty that logs in by itself
if [[ -z "$dm" ]]; then
  dm=$(enabled_units '^(ly|ly@.*|sddm|gdm|lightdm|lxdm|lemurs|emptty|greetd|cosmic-greeter)$' | head -1)
fi
if [[ -z "$dm" ]] && command grep -qs -- '--autologin' /etc/systemd/system/getty@*.service.d/*.conf; then
  dm="a getty autologin"
fi
NEXT=""
if ! $LOGIN; then
  say "skipped (--no-login)"
elif [[ "$dm" == greetd ]] && ! command grep -qs '/etc/greetd/hyprland.lua' /etc/greetd/config.toml; then
  say "greetd is the login screen, set up by something else: it stays as it is. tools/greetd-setup.sh would make it this fork's (ReGreet; it keeps your config.toml next to it)"
  if command grep -qs agreety /etc/greetd/config.toml; then
    NEXT="greetd shows a text login (agreety): log in there and run uwsm start hyprland.desktop, or run tools/greetd-setup.sh for ReGreet"
  else
    NEXT="reboot or log out, then pick \"Hyprland (uwsm-managed)\" if your greeter lists sessions (or run uwsm start hyprland.desktop from it)"
  fi
elif [[ "$dm" == greetd ]]; then
  say "greetd is the login screen: tools/greetd-setup.sh refreshes its colours and wallpaper after your first login"
  NEXT="reboot or log out, then pick \"Hyprland (uwsm-managed)\""
elif [[ "$dm" == "a getty autologin" ]]; then
  say "a TTY logs in by itself here, and stays"
  NEXT="start the session from that login: uwsm start hyprland.desktop (or put it in your shell's login file)"
elif [[ -n "$dm" ]]; then
  say "$dm is the login screen and stays"
  NEXT="log out, then pick \"Hyprland (uwsm-managed)\" on $dm's session menu"
elif ask "No login screen is set up. Install greetd + ReGreet in the fork's style (tools/greetd-setup.sh)?" y; then
  run sudo pacman -S --needed "${NOCONFIRM[@]}" greetd greetd-regreet || die "couldn't install greetd"
  run "$REPO/tools/greetd-setup.sh" || die "tools/greetd-setup.sh failed"
  run sudo systemctl enable greetd.service || die "couldn't enable greetd"
  NEXT="reboot: greetd starts, log in with \"Hyprland (uwsm-managed)\". After the first login, tools/greetd-setup.sh again gives it your colours and wallpaper"
else
  NEXT="from a TTY, log in and run: uwsm start hyprland.desktop"
fi

step "done"
if ((${#WARNINGS[@]})); then
  say "warnings:"; printf '   - %s\n' "${WARNINGS[@]}"
fi
say "next: ${NEXT:-log out and back in}"
say "settings: Super+I (Nexus). Update later with: cd $REPO && git pull && ./install.sh (or Nexus > Updates)"
[[ -n "${LOG:-}" ]] && say "log: $LOG"
exit 0

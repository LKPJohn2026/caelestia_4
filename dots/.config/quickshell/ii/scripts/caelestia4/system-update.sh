#!/usr/bin/env bash
# caelestia4: update everything with no questions: repo packages, AUR packages, then the packages built from this repo and
# the Caelestia plugin if Qt moved to a new minor release. Nexus > Updates and the bar's popout run this in a terminal,
# which closes by itself on success and stays open on a failure.
#
# Shaped after Omarchy's update (one run at a time, free space, no sleeping, pacman in a PID 1 scope). No password with
# the rule of tools/update-sudo-rule.sh; without it sudo asks at the start. What can't be answered safely still stops the
# update: --noconfirm says no to removing a conflicting package, and that is for a person to look at.
set -uo pipefail

self=$(readlink -f -- "${BASH_SOURCE[0]}")
source "$(dirname -- "$self")/tr.sh"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia4"
log_file="$state_dir/update.log"
lock_file="${XDG_RUNTIME_DIR:-/tmp}/caelestia4-update.lock"
system_py="$(dirname -- "$self")/../../modules/caelestia/utils/scripts/system.py"
min_free_gib=10

heading() { printf '\n\e[1;32m:: %s\e[0m\n' "$*"; }
warn() { printf '\e[1;33m:: %s\e[0m\n' "$*" >&2; }
notify() { command -v notify-send >/dev/null && notify-send -a "caelestia-shell" -u "$1" "$2" "${3:-}"; return 0; }

# ---- already running: said before the log below is opened, which would empty that run's
if ! flock -n "$lock_file" true; then
  warn "$(tr_ "An update is already running.")"
  notify normal "$(tr_ "An update is already running.")"
  exit 0
fi

# ---- wrappers: a log of everything, and no sleeping while it runs (each exits with its command's code)
if [[ -z ${C4_UPDATE_LOGGED:-} ]]; then
  mkdir -p "$state_dir"
  export C4_UPDATE_LOGGED=1
  # (script runs this through the login shell, whose own config and quoting are nothing to depend on here: fish, for one)
  SHELL=/usr/bin/bash exec script -qefc "$(printf '%q ' "$self" "$@")" "$log_file"
fi
if [[ -z ${C4_UPDATE_AWAKE:-} ]]; then
  export C4_UPDATE_AWAKE=1
  # (Tried first: its own failure can't be told from the command's. Outside a local session it would ask for a password)
  if command -v systemd-inhibit >/dev/null && systemd-inhibit --no-ask-password --what=sleep:idle true 2>/dev/null; then
    exec systemd-inhibit --no-ask-password --what=sleep:idle --who=caelestia4 --why="Updating packages" "$self" "$@"
  fi
fi

# Nobody is here to answer: a git source that went private fails rather than waiting at "Username:" for good
export GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -oBatchMode=yes"

# Below, what may start a daemon (gpg-agent, for one) doesn't inherit the lock: it would outlive this and hold it for good
exec {lock_fd}>"$lock_file"
flock -n "$lock_fd" || { warn "$(tr_ "An update is already running.")"; exit 0; }

# Ending on a failure: leave the terminal open, the reason is on it
finish_failed() {
  printf '\e[1;31m:: %s\e[0m\n' "$1" >&2
  notify critical "$(tr_ "The update did not finish")" "$1"
  exec {lock_fd}>&-
  if [[ -t 0 ]]; then
    printf '\n%s\n' "$(tr_ "Log: %1" "$log_file")"
    read -rp "$(tr_ "Press Enter to close.") "
  fi
  exit 1
}

avail=$(df --output=avail --block-size=1 / 2>/dev/null | tail -n 1 | tr -d ' ')
if [[ $avail =~ ^[0-9]+$ ]] && ((avail < min_free_gib * 1024 * 1024 * 1024)); then
  finish_failed "$(tr_ "Only %1 GiB free on /: an update needs at least %2 GiB." "$((avail / 1024 / 1024 / 1024))" "$min_free_gib")"
fi

# ---- sudo: the rule (asked by running it, ignoring a password given earlier), or one password kept fresh for long builds
if ! sudo -n -k /usr/bin/pacman --version >/dev/null 2>&1; then
  warn "$(tr_ "No password rule (tools/update-sudo-rule.sh): sudo asks now.")"
  sudo true || finish_failed "$(tr_ "sudo was refused.")"
  (
    exec {lock_fd}>&-
    while kill -0 "$$" 2>/dev/null; do
      sudo -n true 2>/dev/null || exit 0
      sleep 60
    done
  ) &
  keepalive=$!
  trap 'kill "$keepalive" 2>/dev/null' EXIT
fi

# A pacman in this session's scope dies when upgrading systemd re-executes the user manager, half way through its
# transaction. A PID 1 scope survives that
root_pacman() {
  if [[ -d /run/systemd/system ]]; then
    sudo systemd-run --scope --quiet --collect /usr/bin/pacman "$@" {lock_fd}>&-
  else
    sudo /usr/bin/pacman "$@" {lock_fd}>&-
  fi
}

qt_minor() { pacman -Q qt6-base 2>/dev/null | sed -E 's/^\S+ ([0-9]+\.[0-9]+).*/\1/'; }
qt_before=$(qt_minor)

# ---- repo packages. The keyrings first: an old one fails the whole upgrade on a signature. Their failing doesn't stop
# anything: if it matters, the upgrade says so
keyrings=()
for k in archlinux-keyring cachyos-keyring; do
  pacman -Q "$k" >/dev/null 2>&1 && pacman -Si "$k" >/dev/null 2>&1 && keyrings+=("$k")
done
if ((${#keyrings[@]})); then
  heading "$(tr_ "Signing keys")"
  root_pacman -Sy --needed --noconfirm "${keyrings[@]}" || warn "$(tr_ "The signing keys could not be updated.")"
fi

heading "$(tr_ "Repo packages")"
root_pacman -Syu --noconfirm || finish_failed "$(tr_ "pacman stopped: read why above. Nothing from the AUR was touched.")"

# ---- AUR packages. Reviewing them is what gets skipped here. This fork's own packages are built from its repo: one with
# the same name on the AUR would otherwise be built and installed by nobody's choice
aur_failed=""
aur_skipped=""
helper=""
for h in yay paru; do
  command -v "$h" >/dev/null && { helper=$h; break; }
done
if [[ -n $(pacman -Qqm 2>/dev/null) ]]; then
  if [[ -z $helper ]]; then
    aur_skipped=1
  elif curl -sf --connect-timeout 30 --retry 2 -A "caelestia4-update" -o /dev/null "https://aur.archlinux.org/rpc/?v=5&type=info&arg=base"; then
    heading "$(tr_ "AUR packages (%1)" "$helper")"
    own=$(pacman -Qqm | grep -E '^(caelestia4-|illogical-impulse-)' | paste -sd, -)
    aur_args=(-Sua --noconfirm --cleanafter)
    [[ -n $own ]] && aur_args+=(--ignore "$own")
    # (A sudo loop in the helper's config runs sudo -v, which the rule doesn't cover)
    if [[ $helper == yay ]]; then
      aur_args+=(--answerclean None --answerdiff None --answeredit None --removemake --sudoloop=false)
    else
      aur_args+=(--skipreview --removemake --nosudoloop)
    fi
    # (A language's own toolchain settings would build with the wrong Go)
    env -u GOROOT -u GOBIN "$helper" "${aur_args[@]}" {lock_fd}>&- || aur_failed=$(tr_ "%1 stopped: read why above." "$helper")
  else
    aur_skipped=1
    warn "$(tr_ "The AUR can't be reached: its packages are left for next time.")"
  fi
fi

# ---- everything of ours linking Qt's private API needs a rebuild on any new Qt minor. Also asked of the check Nexus shows,
# so a rebuild left over from an earlier failure is done too. Built, then installed through root_pacman: makepkg -i runs
# sudo -k, which would ask again without the rule, after a long build
components=$(python3 "$system_py" components 2>/dev/null) || components=""
needs() {
  COMPONENTS="$components" python3 -c '
import json, os, sys
try:
    data = json.loads(os.environ["COMPONENTS"])
except ValueError:
    sys.exit(2)
sys.exit(0 if any(c["name"] == sys.argv[1] and c.get("needsRebuild") for c in data["components"]) else 1)' "$1"
}
build_local() {
  local dir="$repo/packaging/$1" pkgs=() p
  (cd "$dir" && makepkg -Cfs --noconfirm {lock_fd}>&-) || return 1
  while read -r p; do
    [[ -f $p && $p != *-debug-* ]] && pkgs+=("$p")
  done < <(cd "$dir" && makepkg --packagelist)
  ((${#pkgs[@]})) && root_pacman -U --noconfirm "${pkgs[@]}"
}
repo=$(COMPONENTS="$components" python3 -c 'import json, os; print(json.loads(os.environ["COMPONENTS"]).get("repo", ""))' 2>/dev/null)
qt_after=$(qt_minor)
rebuilt=""
rebuild_failed=""
if [[ $qt_before != "$qt_after" ]] || needs "Quickshell" || needs "Caelestia plugin"; then
  heading "$(tr_ "Qt %1 to %2: rebuilding the shell" "${qt_before:-?}" "${qt_after:-?}")"
  if [[ -z $repo || ! -d $repo/packaging/caelestia4-quickshell ]]; then
    rebuild_failed=$(tr_ "The caelestia_4 clone wasn't found: rebuild Quickshell and the plugin by hand (docs/install.md).")
  else
    for p in caelestia4-quickshell caelestia4-qtengine caelestia4-atlas caelestia4-wormhole; do
      if pacman -Q "$p" >/dev/null 2>&1 && [[ -d $repo/packaging/$p ]]; then
        build_local "$p" || rebuild_failed="${rebuild_failed:+$rebuild_failed, }$p"
      fi
    done
    "$repo/tools/build-caelestia-plugin.sh" {lock_fd}>&- || rebuild_failed="${rebuild_failed:+$rebuild_failed, }Caelestia plugin"
    if [[ -n $rebuild_failed ]]; then
      rebuild_failed=$(tr_ "%1 didn't build: don't restart the shell until it does (docs/install.md)." "$rebuild_failed")
    else
      rebuilt=1
    fi
  fi
fi

[[ -z $rebuild_failed ]] || finish_failed "$rebuild_failed${aur_failed:+ $aur_failed}"
[[ -z $aur_failed ]] || finish_failed "$aur_failed"

# ---- done: what's left to do goes into the notification, as the terminal closes
message=""
note() { message="${message:+$message }$1"; }
if command -v pacdiff >/dev/null; then
  pacnew=$(pacdiff -o 2>/dev/null | wc -l)
  ((pacnew > 0)) && note "$(tr_ "%1 config files have a .pacnew to merge (pacdiff)." "$pacnew")"
fi
[[ -d /usr/lib/modules/$(uname -r) ]] || note "$(tr_ "A new kernel is installed: restart when you can.")"
title=$(tr_ "Everything is up to date")
[[ -z $aur_skipped ]] || title=$(tr_ "Repo packages updated; AUR packages left for next time")

heading "$(tr_ "Done")"

if [[ -z $rebuilt ]]; then
  notify normal "$title" "$message"
  exit 0
fi

# The running shell still has the old Qt loaded. Not under a game or a lock screen: restarting the shell's own lock
# (lock.useHyprlock off) would kill it, so that one waits for the person whether locked or not. The notification goes
# first, as the shell is what shows it, and the check too, as the new shell reads the last one
fullscreen=$(hyprctl clients -j 2>/dev/null | jq '[.[] | select(.fullscreen != 0 and .fullscreen != false)] | length' 2>/dev/null)
hyprlock_used=$(jq -r '.lock.useHyprlock // false' "${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json" 2>/dev/null)
# (Tracked files only: an unfinished change or rebase went into that build, and the person should choose when it loads)
local_changes=$(git -C "$repo" status --porcelain --untracked-files=no 2>/dev/null)
[[ -z $local_changes ]] || note "$(tr_ "The caelestia_4 clone has local changes, and the rebuild includes them.")"
if [[ $fullscreen == 0 && $hyprlock_used == true && -z $local_changes ]] && ! pgrep -x hyprlock >/dev/null; then
  python3 "$system_py" updates >/dev/null 2>&1
  notify normal "$title" "$message"
  systemctl --user restart caelestia4-shell.service {lock_fd}>&- || finish_failed "$(tr_ "The shell didn't restart: systemctl --user status caelestia4-shell")"
else
  note "$(tr_ "The shell was rebuilt: run systemctl --user restart caelestia4-shell when you can.")"
  notify normal "$title" "$message"
fi
exit 0

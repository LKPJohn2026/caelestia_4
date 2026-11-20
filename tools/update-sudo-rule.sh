#!/usr/bin/env bash
# caelestia4: lets this account run the repo part of an update with no password (scripts/caelestia4/system-update.sh,
# the Update everything button in Nexus > Updates), like Omarchy's passwordless sudo but for two pacman commands rather
# than for every command.
#
# The rule names exact commands, with no wildcards: pacman -Syu --noconfirm (the repo upgrade) and
# pacman -Sy --needed --noconfirm with the keyrings the update refreshes first, each also in the form root_pacman runs it
# in (systemd-run --scope --quiet --collect /usr/bin/pacman ...). Those install only signed packages from the repos in
# /etc/pacman.conf, so nothing under this account can become root through the rule. Everything else still asks for the
# password: pacman -U, -R, -D and -S of other packages, yay and paru, makepkg's build dependencies. The update asks for it
# right before the AUR step or a rebuild of this repo's Qt packages, and only when that step has something to do.
#
# An older version of this tool allowed pacman with any arguments, which is close to root (pacman -U installs any
# package). Status says when that rule is still there: run enable again to replace it with this one. It also says when
# another sudoers file lets pacman run with any arguments, which this tool can't change, and "can't tell" when sudo
# doesn't say (it lists rules only with a password, or lists them in another form); with sudo it also says whether the
# rule file is there, which only root can see.
#
#   sudo tools/update-sudo-rule.sh enable
#   sudo tools/update-sudo-rule.sh disable
#   tools/update-sudo-rule.sh status          (no sudo needed; with sudo, for the account that ran it)
# shellcheck disable=SC2154 # (the c4_ variables are set by update-sudo-state.sh, sourced below)
set -euo pipefail

here=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
# The command list and the check, shared with the update itself
state_script="$here/../dots/.config/quickshell/ii/scripts/caelestia4/update-sudo-state.sh"
# shellcheck source=SCRIPTDIR/../dots/.config/quickshell/ii/scripts/caelestia4/update-sudo-state.sh
source "$state_script"

rule_file=$c4_rule_file

usage() {
  echo "Usage: sudo $0 enable|disable, or $0 status" >&2
  exit 2
}

require_root() {
  [[ $(id -u) -eq 0 ]] || { echo "Run this with sudo: sudo $0 $1" >&2; exit 1; }
}

# The rule's commands, one per line: both forms of the repo upgrade, then of each non-empty set of keyrings in the
# order system-update.sh names them (it names only the installed ones, and the set can change later)
rule_commands() {
  local n=${#c4_keyrings[@]} mask i args prefix
  for prefix in "/usr/bin/pacman" "/usr/bin/systemd-run --scope --quiet --collect /usr/bin/pacman"; do
    echo "$prefix -Syu --noconfirm"
    for ((mask = 1; mask < 1 << n; mask++)); do
      args=""
      for ((i = 0; i < n; i++)); do
        ((mask & 1 << i)) && args+=" ${c4_keyrings[i]}"
      done
      echo "$prefix -Sy --needed --noconfirm$args"
    done
  done
}

# What sudo does for the account now, asked as that account: c4_state, c4_source and c4_entry as update-sudo-state.sh
# sets them (it prints them). Then what this file holds, which only root can read: c4_rule_kind
account_state() {
  local out line1
  out=$(sudo -u "$1" env C4_SUDOERS_DIR="$(dirname -- "$rule_file")" bash "$state_script" 2>/dev/null) || out="off"
  line1=$(sed -n 1p <<<"$out")
  c4_state=${line1%% *}
  c4_source=""
  [[ $line1 != *" "* ]] || c4_source=${line1#* }
  c4_entry=$(sed -n 2p <<<"$out")
  c4_rule_kind
}

# Why sudo doesn't say (c4_state unknown, or off with c4_source unlisted)
why_unsure() {
  if [[ $c4_state == unknown ]]; then
    echo "this sudo lists rules in a form this tool can't read"
  else
    echo "sudo lists $1's rules only with a password, as Defaults listpw in sudoers says"
  fi
}

# Status when sudo doesn't say but the rule file is in sight (as root): can't tell, rather than off
cant_tell() {
  case $c4_rule_kind in
    wide) echo "can't tell ($(why_unsure "$1"); rule file present: $rule_file, the older pacman-wide one: run enable again to narrow it)" ;;
    "") echo "can't tell ($(why_unsure "$1"))" ;;
    *) echo "can't tell ($(why_unsure "$1"); rule file present: $rule_file)" ;;
  esac
}

case "${1:-}" in
  enable)
    require_root enable
    # The account that ran sudo. Sudoers has metacharacters and reads an upper-case word as an alias: names outside this
    # portable set are refused rather than quoted into a security rule
    account=${SUDO_USER:-}
    [[ $account =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { echo "Run this through sudo from a normal account (got '${account}')." >&2; exit 1; }
    [[ $account != root ]] || { echo "Run this through sudo from your own account, not from root." >&2; exit 1; }
    # (Package names go into the rule as they are: only characters sudoers reads literally)
    for k in "${c4_keyrings[@]}"; do
      [[ $k =~ ^[a-z0-9][a-z0-9._+-]*$ ]] || { echo "Unexpected keyring name '$k': nothing changed." >&2; exit 1; }
    done

    # (A dot in the name: sudo doesn't read this file until it has passed visudo and is renamed)
    tmp=$(mktemp "$(dirname "$rule_file")/.caelestia4-update.XXXXXX")
    trap 'rm -f "${tmp:?}"' EXIT
    {
      echo "# Made by caelestia_4's tools/update-sudo-rule.sh (disable with it, or delete this file). Only the keyrings and"
      echo "# the repo upgrade of scripts/caelestia4/system-update.sh, exactly as it runs them; anything else asks."
      printf '%s ALL=(root) NOPASSWD: ' "$account"
      mapfile -t commands < <(rule_commands)
      for ((i = 0; i < ${#commands[@]}; i++)); do
        ((i == 0)) || printf ', \\\n    '
        printf '%s' "${commands[i]}"
      done
      printf '\n'
    } >"$tmp"
    chmod 0440 "$tmp"
    chown root:root "$tmp"
    visudo -cqf "$tmp" || { echo "visudo refused the rule: nothing changed." >&2; exit 1; }
    mv -f "$tmp" "$rule_file"
    trap - EXIT
    account_state "$account"
    case $c4_state in
      split)
        echo "On: $account upgrades repo packages with no password; AUR updates and rebuilds ask. To undo: sudo $0 disable"
        ;;
      wide)
        echo "The rule is in place, but another sudoers rule (${c4_entry:-read after it}) still lets $account run any pacman command with no password." >&2
        ;;
      *)
        if [[ $c4_state == unknown || $c4_source == unlisted ]]; then
          echo "The rule is in place, but $(why_unsure "$account"): the update can't tell, and asks for the password at the start." >&2
        else
          echo "The rule is in place, but sudo still asks $account for a password: another rule read after it wins${c4_entry:+ ($c4_entry)}." >&2
          exit 1
        fi
        ;;
    esac
    ;;
  disable)
    require_root disable
    rm -f "${rule_file:?}"
    account=${SUDO_USER:-}
    [[ -z $account ]] || account_state "$account"
    if [[ -n $account && ($c4_state == split || $c4_state == wide) ]]; then
      echo "This rule is gone, but another sudoers rule (${c4_entry:-unknown file}) still lets $account upgrade packages with no password." >&2
    else
      echo "Off: updating packages asks for the password again."
    fi
    ;;
  status)
    # Under sudo, the account that ran it: root's own rule always asks
    if [[ $(id -u) -eq 0 && -n ${SUDO_USER:-} && $SUDO_USER != root ]]; then
      account=$SUDO_USER
      account_state "$account"
    else
      account=$(id -un)
      c4_sudo_state
      c4_rule_kind
    fi
    case $c4_state in
      split) echo "on (split)" ;;
      wide)
        if [[ $c4_source == own ]]; then
          echo "on (pacman-wide, older rule: run enable again to narrow it)"
        else
          echo "on (pacman-wide, from ${c4_entry:-another sudoers rule}: enable can't narrow that one)"
        fi
        ;;
      unknown) cant_tell "$account" ;;
      *)
        if [[ $c4_source == unlisted && -n $c4_rule_kind ]]; then
          cant_tell "$account"
        else
          echo "off"
        fi
        ;;
    esac
    ;;
  *)
    usage
    ;;
esac

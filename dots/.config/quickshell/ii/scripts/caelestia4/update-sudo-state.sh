#!/usr/bin/env bash
# shellcheck shell=bash
# caelestia4: the root commands of system-update.sh that tools/update-sudo-rule.sh lets run with no password, and how
# sudo treats them now. Sourced by both, and run by Nexus > Updates, which reads what it prints: the state on the first
# line, the sudoers file of the rule that decided it on the second (empty when sudo doesn't say):
#   split       the keyrings and the repo upgrade run with no password; everything else asks (the rule of
#               update-sudo-rule.sh)
#   wide own    any pacman command runs with no password, through the older rule of update-sudo-rule.sh (enable narrows it)
#   wide other  the same through another sudoers file, which update-sudo-rule.sh can't change
#   off         the repo upgrade asks for the password; "off unlisted" when sudo wouldn't even list it without one
#   unknown     sudo listed the command, but not in a form this can read (another sudo, such as sudo-rs)
#
# Asked with sudo -n -k -ll COMMAND, which runs nothing: it prints the rule that would apply (the last one that matches)
# and says "!authenticate" when that rule has NOPASSWD. Its exit code alone isn't enough, as a command allowed with a
# password lists too. -k leaves a password given earlier out of it, and -n makes a listing that needs a password fail
# instead of asking: by default (listpw=any) listing needs none once any rule of the account has NOPASSWD. With
# listpw=all or always it needs one anyway: that reads as "off unlisted", and the update then asks at the start. The
# account can't read /etc/sudoers.d, so only update-sudo-rule.sh, as root, can tell that case from no rule at all.

# zz: sudo takes the last rule that matches, and the files in this folder are read in name order
c4_rule_file="${C4_SUDOERS_DIR:-/etc/sudoers.d}/zz-caelestia4-update"

# The keyrings system-update.sh updates first, in this order, when installed and in a sync db. The rule allows each
# non-empty set of them in this order, so a keyring installed or removed later still runs with no password
# shellcheck disable=SC2034 # (read by the scripts that source this)
c4_keyrings=(archlinux-keyring cachyos-keyring)

# The command root_pacman runs, in c4_cmd: in a PID 1 scope where systemd is running (see system-update.sh)
c4_pacman_cmd() {
  if [[ -d /run/systemd/system ]]; then
    c4_cmd=(/usr/bin/systemd-run --scope --quiet --collect /usr/bin/pacman "$@")
  else
    c4_cmd=(/usr/bin/pacman "$@")
  fi
}

# Whether sudo runs this exact command with no password: 0 yes, 1 no, 2 can't tell. c4_entry is the file of the rule
# that applies; c4_unlisted is set when sudo wanted a password to list it at all
c4_nopasswd() {
  local out err rc
  c4_entry=""
  c4_unlisted=""
  err=$(mktemp) || return 2
  # (Written so a caller's set -e doesn't stop on the answer no)
  out=$(LC_ALL=C sudo -n -k -ll -- "$@" 2>"$err") && rc=0 || rc=$?
  err=$(cat -- "$err"; rm -f -- "$err")
  if ((rc != 0)); then
    # (Not allowed: sudo says nothing. Anything else it says, such as an option it doesn't know, leaves it open)
    if [[ -z $err ]]; then
      return 1
    elif [[ $err == *"password is required"* ]]; then
      c4_unlisted=1
      return 1
    fi
    return 2
  fi
  c4_entry=$(sed -nE 's/^Sudoers entry: (.*)$/\1/p' <<<"$out" | tail -n 1)
  [[ -n $c4_entry ]] || return 2
  grep -Eq '^[[:space:]]*Options:(.*[ ,])?!authenticate(,|$)' <<<"$out"
}

# c4_state and c4_source: the first line above, in two words (c4_source is own, other or unlisted, or empty); c4_entry
# is the file of the rule that decided it
c4_sudo_state() {
  local rc
  c4_state="off"
  c4_source=""
  c4_pacman_cmd -Syu --noconfirm
  c4_nopasswd "${c4_cmd[@]}" && rc=0 || rc=$?
  if ((rc == 2)); then
    c4_state="unknown"
    return 0
  elif ((rc == 1)); then
    [[ -z $c4_unlisted ]] || c4_source="unlisted"
    return 0
  fi
  # Any package file stands for every other pacman command. Either form is enough: yay, paru and makepkg run plain
  # sudo pacman, and the scope only wraps it
  local entry=$c4_entry
  c4_pacman_cmd -U --noconfirm caelestia4-check.pkg.tar.zst
  if c4_nopasswd /usr/bin/pacman -U --noconfirm caelestia4-check.pkg.tar.zst || c4_nopasswd "${c4_cmd[@]}"; then
    c4_state="wide"
    c4_source="other"
    [[ $c4_entry != "$c4_rule_file" ]] || c4_source="own"
  else
    c4_entry=$entry
    c4_state="split"
  fi
}

# What c4_rule_file holds, for root, who can read it: c4_rule_kind is split, wide (the older rule), other, present
# (there but unreadable), or empty when it isn't there or its folder can't be read
# shellcheck disable=SC2034 # (read by update-sudo-rule.sh)
c4_rule_kind() {
  c4_rule_kind=""
  [[ -e $c4_rule_file ]] || return 0
  c4_rule_kind="present"
  [[ -r $c4_rule_file ]] || return 0
  if grep -Eq '^[^#]*NOPASSWD:[[:space:]]*/usr/bin/pacman[[:space:]]*(,|$)' "$c4_rule_file"; then
    c4_rule_kind="wide"
  elif grep -Eq '^[^#]*-Syu --noconfirm' "$c4_rule_file"; then
    c4_rule_kind="split"
  else
    c4_rule_kind="other"
  fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  c4_sudo_state
  echo "$c4_state${c4_source:+ $c4_source}"
  echo "$c4_entry"
fi

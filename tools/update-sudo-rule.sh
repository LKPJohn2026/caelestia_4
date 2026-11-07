#!/usr/bin/env bash
# caelestia4: lets this account update packages with no password (scripts/caelestia4/system-update.sh, the Update
# everything button in Nexus > Updates), like Omarchy's passwordless sudo but for pacman alone rather than for every
# command.
#
# It is still root in practice: `sudo pacman -U` installs any package, and packages run scripts as root. Any program
# running under this account could use the rule, without asking. Turn it off if that isn't what you want.
#
#   sudo tools/update-sudo-rule.sh enable
#   sudo tools/update-sudo-rule.sh disable
#   tools/update-sudo-rule.sh status          (no sudo needed)
set -euo pipefail

# zz: sudo takes the last rule that matches, and the files in this folder are read in name order
rule_file="${C4_SUDOERS_DIR:-/etc/sudoers.d}/zz-caelestia4-update"

# Whether pacman runs with no password, by running it: a password given earlier doesn't count. Whatever rule allows it
no_password() {
  sudo -n -k /usr/bin/pacman --version >/dev/null 2>&1
}

usage() {
  echo "Usage: sudo $0 enable|disable, or $0 status" >&2
  exit 2
}

require_root() {
  [[ $(id -u) -eq 0 ]] || { echo "Run this with sudo: sudo $0 $1" >&2; exit 1; }
}

case "${1:-}" in
  enable)
    require_root enable
    # The account that ran sudo. Sudoers has metacharacters and reads an upper-case word as an alias: names outside this
    # portable set are refused rather than quoted into a security rule
    account=${SUDO_USER:-}
    [[ $account =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { echo "Run this through sudo from a normal account (got '${account}')." >&2; exit 1; }
    [[ $account != root ]] || { echo "Run this through sudo from your own account, not from root." >&2; exit 1; }

    # (A dot in the name: sudo doesn't read this file until it has passed visudo and is renamed)
    tmp=$(mktemp "$(dirname "$rule_file")/.caelestia4-update.XXXXXX")
    trap 'rm -f "${tmp:?}"' EXIT
    cat >"$tmp" <<EOF
# Made by caelestia_4's tools/update-sudo-rule.sh (disable with it, or delete this file)
$account ALL=(root) NOPASSWD: /usr/bin/pacman, /usr/bin/systemd-run --scope --quiet --collect /usr/bin/pacman *
EOF
    chmod 0440 "$tmp"
    chown root:root "$tmp"
    visudo -cqf "$tmp" || { echo "visudo refused the rule: nothing changed." >&2; exit 1; }
    mv -f "$tmp" "$rule_file"
    trap - EXIT
    if sudo -u "$account" sudo -n -k /usr/bin/pacman --version >/dev/null 2>&1; then
      echo "On: $account updates packages with no password. To undo: sudo $0 disable"
    else
      echo "The rule is in place, but sudo still asks $account for a password: another rule read after it wins." >&2
      exit 1
    fi
    ;;
  disable)
    require_root disable
    rm -f "${rule_file:?}"
    account=${SUDO_USER:-}
    if [[ -n $account ]] && sudo -u "$account" sudo -n -k /usr/bin/pacman --version >/dev/null 2>&1; then
      echo "This rule is gone, but another sudoers rule still lets $account run pacman with no password." >&2
    else
      echo "Off: updating packages asks for the password again."
    fi
    ;;
  status)
    if no_password; then
      echo "on"
    else
      echo "off"
    fi
    ;;
  *)
    usage
    ;;
esac

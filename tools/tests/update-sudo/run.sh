#!/usr/bin/env bash
# Tests for tools/update-sudo-rule.sh and scripts/caelestia4/update-sudo-state.sh, the sudoers rule of the passwordless
# repo upgrade. Copies of both run in a temporary directory, with C4_SUDOERS_DIR there and stub sudo (stubs/sudo.sh),
# id, chown and visudo on PATH: nothing runs as root, /etc is never read or written. Checked: the rule names exactly
# the 8 commands (2 forms x the repo upgrade and each set of keyrings) with no wildcard, and passes visudo -c when visudo
# is installed; bad account and keyring names are refused; the state sudo -ll gives reads as split, wide own, wide
# other, off, off unlisted or unknown; the kind of rule file (split, wide, other, present).
# Usage: tools/tests/update-sudo/run.sh
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fails=0
ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails + 1)); }

real_visudo=$(PATH="$PATH:/usr/sbin:/sbin" command -v visudo || true)

# The tool and the state script at the same relative places
state_rel=dots/.config/quickshell/ii/scripts/caelestia4/update-sudo-state.sh
mkdir -p "$tmp/tree/tools" "$(dirname "$tmp/tree/$state_rel")"
cp "$repo/tools/update-sudo-rule.sh" "$tmp/tree/tools/"
cp "$repo/$state_rel" "$tmp/tree/$state_rel"
tool="$tmp/tree/tools/update-sudo-rule.sh"
state="$tmp/tree/$state_rel"

# Stubs: sudo (shared with the system-update test), id (root when STUB_UID=0), chown (root:root only exists as root),
# visudo (the real one's check when installed, never anything else)
bin="$tmp/bin"
mkdir -p "$bin" "$tmp/state"
cp "$here/stubs/sudo.sh" "$bin/sudo"
cat >"$bin/id" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  -u) echo "${STUB_UID:-0}" ;;
  -un) echo "${STUB_USER:-bob}" ;;
  *) exec /usr/bin/env -i PATH=/usr/bin:/bin id "$@" ;;
esac
SH
cat >"$bin/chown" <<'SH'
#!/usr/bin/env bash
echo "chown $*" >>"$STUB_LOG"
SH
cat >"$bin/visudo" <<SH
#!/usr/bin/env bash
[[ -n "$real_visudo" ]] || exit 0
exec "$real_visudo" "\$@"
SH
chmod +x "$bin"/*
export PATH="$bin:$PATH" STUB_LOG="$tmp/log" STUB_STATE="$tmp/state" LC_ALL=C
sudoers="$tmp/sudoers.d"
mkdir -p "$sudoers"
export C4_SUDOERS_DIR="$sudoers"
rule="$sudoers/zz-caelestia4-update"

# ---- 1. the rule
STUB_SUDO_MODE=split SUDO_USER=bob STUB_UID=0 bash "$tool" enable >"$tmp/out" 2>&1 || bad "enable failed: $(cat "$tmp/out")"
if [[ -f $rule ]]; then
  [[ $(stat -c %a "$rule") == 440 ]] && ok "rule file is 0440" || bad "rule file mode $(stat -c %a "$rule")"
  grep -q '^On: bob upgrades repo packages with no password' "$tmp/out" && ok "enable reports split" \
    || bad "enable said: $(cat "$tmp/out")"
  head_line=$(grep -v '^#' "$rule" | head -n 1)
  [[ $head_line == "bob ALL=(root) NOPASSWD: /usr/bin/pacman -Syu --noconfirm, \\" ]] && ok "rule is for bob, as root, NOPASSWD" \
    || bad "rule starts: $head_line"
  got=$(grep -v '^#' "$rule" | sed 's/\\$//' | tr '\n' ' ' | sed -E 's/^[^:]*NOPASSWD:[[:space:]]*//; s/[[:space:]]+/ /g; s/ ,/,/g; s/[[:space:]]*$//' | sed 's/, /\n/g')
  want="/usr/bin/pacman -Syu --noconfirm
/usr/bin/pacman -Sy --needed --noconfirm archlinux-keyring
/usr/bin/pacman -Sy --needed --noconfirm cachyos-keyring
/usr/bin/pacman -Sy --needed --noconfirm archlinux-keyring cachyos-keyring
/usr/bin/systemd-run --scope --quiet --collect /usr/bin/pacman -Syu --noconfirm
/usr/bin/systemd-run --scope --quiet --collect /usr/bin/pacman -Sy --needed --noconfirm archlinux-keyring
/usr/bin/systemd-run --scope --quiet --collect /usr/bin/pacman -Sy --needed --noconfirm cachyos-keyring
/usr/bin/systemd-run --scope --quiet --collect /usr/bin/pacman -Sy --needed --noconfirm archlinux-keyring cachyos-keyring"
  [[ $got == "$want" ]] && ok "exactly the 8 commands" || bad "rule commands differ:"$'\n'"$got"
  if grep -v '^#' "$rule" | grep -q '[*?[]'; then bad "the rule has a wildcard"; else ok "no wildcard"; fi
  if grep -v '^#' "$rule" | grep -Eq '(^|[:,][[:space:]]*)(/usr/bin/)?(pacman|systemd-run)[[:space:]]*(,|\\?$)'; then
    bad "a command with no arguments (any arguments) is allowed"
  else
    ok "every command has its arguments"
  fi
  if [[ -n $real_visudo ]]; then
    if "$real_visudo" -cf "$rule" >/dev/null 2>&1; then ok "visudo -c accepts the rule"; else bad "visudo -c refused the rule"; fi
  elif [[ ${CI:-} == true ]]; then
    bad "visudo is not installed (CI=true: the rule's syntax must be checked)"
  else
    echo "skip: visudo is not installed (the rule's syntax isn't checked)"
  fi
  # A second enable gives the same file
  cp "$rule" "$tmp/rule.first"
  STUB_SUDO_MODE=split SUDO_USER=bob STUB_UID=0 bash "$tool" enable >/dev/null 2>&1 || true
  cmp -s "$rule" "$tmp/rule.first" && ok "enable again: same rule" || bad "enable again changed the rule"
else
  bad "enable wrote no rule: $(cat "$tmp/out")"
fi
leftovers=$(find "$sudoers" -name '.caelestia4-update.*' | wc -l)
[[ $leftovers -eq 0 ]] && ok "no temporary file left" || bad "$leftovers temporary files left"

# ---- 2. what enable refuses: nothing written
for account in root ALL Bob "a b" "x,y" "" "-bob" "bob:x" "b%c"; do
  rm -f "$rule"
  rc=0
  STUB_SUDO_MODE=split SUDO_USER=$account STUB_UID=0 bash "$tool" enable >/dev/null 2>&1 || rc=$?
  if [[ $rc -ne 0 && ! -e $rule ]]; then ok "account '$account' refused"; else bad "account '$account' gave $rc, rule written: $([[ -e $rule ]] && echo yes || echo no)"; fi
done
rm -f "$rule"
rc=0
STUB_SUDO_MODE=split SUDO_USER=bob STUB_UID=1000 bash "$tool" enable >/dev/null 2>&1 || rc=$?
[[ $rc -ne 0 && ! -e $rule ]] && ok "enable without root refused" || bad "enable without root gave $rc"
cp "$state" "$state.orig"
for k in "bad name" "a,b" "x*" "ALL" "-x" "a:b"; do
  # (c4_keyrings in the copy: archlinux-keyring and this one)
  sed "s/^c4_keyrings=(archlinux-keyring cachyos-keyring)$/c4_keyrings=(archlinux-keyring \"$k\")/" "$state.orig" >"$state"
  grep -qF "\"$k\")" "$state" || { bad "couldn't put keyring '$k' in the copy"; continue; }
  rc=0
  STUB_SUDO_MODE=split SUDO_USER=bob STUB_UID=0 bash "$tool" enable >/dev/null 2>&1 || rc=$?
  if [[ $rc -ne 0 && ! -e $rule ]]; then ok "keyring '$k' refused"; else bad "keyring '$k' gave $rc"; fi
done
cp "$state.orig" "$state"

# ---- 3. the state, from what sudo -ll says
STUB_SUDO_MODE=split SUDO_USER=bob STUB_UID=0 bash "$tool" enable >/dev/null 2>&1 || true
expect_state() { # MODE FIRST-LINE SECOND-LINE
  local out
  out=$(STUB_SUDO_MODE=$1 STUB_UID=1000 bash "$state" 2>&1) || { bad "state ($1): exit $?"; return; }
  if [[ $(sed -n 1p <<<"$out") == "$2" && $(sed -n 2p <<<"$out") == "$3" ]]; then
    ok "state $1: $2"
  else
    bad "state $1: got '$(tr '\n' '|' <<<"$out")', want '$2|$3'"
  fi
}
expect_state split "split" "$rule"
expect_state wide-own "wide own" "$rule"
expect_state wide-other "wide other" "/etc/sudoers.d/10-pacman"
expect_state password "off" "/etc/sudoers"
expect_state off "off" ""
expect_state unlisted "off unlisted" ""
expect_state unknown "unknown" ""
expect_state odd "unknown" ""

# status as the account, and as root through sudo (who can see the rule file)
expect_status() { # MODE UID WANT-PREFIX
  local out
  out=$(STUB_SUDO_MODE=$1 STUB_UID=$2 SUDO_USER=bob bash "$tool" status 2>&1) || { bad "status ($1): exit $?"; return; }
  if [[ $out == "$3"* ]]; then ok "status $1 (uid $2): $out"; else bad "status $1 (uid $2): '$out', want '$3...'"; fi
}
expect_status split 1000 "on (split)"
expect_status wide-own 1000 "on (pacman-wide, older rule"
expect_status wide-other 1000 "on (pacman-wide, from /etc/sudoers.d/10-pacman"
expect_status off 1000 "off"
# (Here the account can see the rule file, as only root can on a real system)
expect_status unlisted 1000 "can't tell (sudo lists bob's rules only with a password"
expect_status unlisted 0 "can't tell (sudo lists bob's rules only with a password"
expect_status unknown 0 "can't tell (this sudo lists rules in a form"
mv "$rule" "$tmp/rule.kept"
expect_status unlisted 1000 "off"
expect_status unlisted 0 "off"
mv "$tmp/rule.kept" "$rule"

# ---- 4. the kind of rule file
# shellcheck source=/dev/null # (a copy of update-sudo-state.sh)
. "$state"
kind_of() { # TEXT WANT
  rm -f "$rule"
  printf '%s\n' "$1" >"$rule"
  chmod 0440 "$rule"
  c4_rule_kind
  if [[ $c4_rule_kind == "$2" ]]; then ok "rule kind $2"; else bad "rule kind: got '$c4_rule_kind', want '$2' for: $1"; fi
}
kind_of "bob ALL=(root) NOPASSWD: /usr/bin/pacman" wide
kind_of "bob ALL=(root) NOPASSWD: /usr/bin/pacman, /usr/bin/true" wide
kind_of "$(cat "$tmp/rule.first")" split
kind_of "bob ALL=(root) NOPASSWD: /usr/bin/true" other
kind_of "# bob ALL=(root) NOPASSWD: /usr/bin/pacman" other
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  chmod 000 "$rule"
  c4_rule_kind
  [[ $c4_rule_kind == present ]] && ok "rule kind present (unreadable)" || bad "unreadable rule: '$c4_rule_kind'"
  chmod 0440 "$rule"
fi
rm -f "$rule"
c4_rule_kind
[[ -z $c4_rule_kind ]] && ok "rule kind empty (no file)" || bad "no file: '$c4_rule_kind'"

# ---- 5. disable removes it
STUB_SUDO_MODE=split SUDO_USER=bob STUB_UID=0 bash "$tool" enable >/dev/null 2>&1 || true
out=$(STUB_SUDO_MODE=off SUDO_USER=bob STUB_UID=0 bash "$tool" disable 2>&1) || bad "disable failed: $out"
[[ ! -e $rule && $out == "Off:"* ]] && ok "disable removes the rule" || bad "disable: '$out'"

if ((fails)); then
  echo "update-sudo tests: $fails FAILED"
  exit 1
fi
echo "update-sudo tests: OK"

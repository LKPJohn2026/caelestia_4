#!/usr/bin/env bash
# A stand-in for sudo in the update tests (tools/tests/update-sudo, tools/tests/system-update): runs nothing as root and
# asks for nothing; it writes what it was asked to $STUB_LOG and answers as $STUB_SUDO_MODE says:
#   split       the commands of $C4_SUDOERS_DIR/zz-caelestia4-update run with no password, anything else asks
#   wide-own    any command, no password, through that file      wide-other  the same through another sudoers file
#   password    allowed, with a password                         off         not allowed (sudo -ll says nothing)
#   unlisted    sudo wants a password to list at all             unknown     listed in a form update-sudo-state.sh can't read
#   odd         an error update-sudo-state.sh doesn't know
# sudo -v asks for the password: logged as ASK, refused when STUB_SUDO_REFUSE=1. A command that would need a password
# before one was given is logged as IMPLICIT-ASK (sudo would prompt in the middle of the update).
set -uo pipefail
log=${STUB_LOG:-/dev/null}
mode=${STUB_SUDO_MODE:-off}
rule_file="${C4_SUDOERS_DIR:-/nonexistent}/zz-caelestia4-update"
given="${STUB_STATE:-/nonexistent}/password-given"

# The commands of the rule file, one per line (it continues lines with ", \")
rule_commands() {
  [[ -r $rule_file ]] || return 0
  grep -v '^#' "$rule_file" | sed 's/\\$//' | tr '\n' ' ' \
    | sed -E 's/^[^:]*NOPASSWD:[[:space:]]*//; s/[[:space:]]+/ /g; s/ ,/,/g; s/[[:space:]]*$//' | sed 's/, /\n/g'
}

# Whether this exact command runs with no password: yes, password (allowed with one) or no
allowed() {
  case $mode in
    split) if rule_commands | grep -Fxq -- "$1"; then echo yes; else echo no; fi ;;
    wide-own | wide-other | unknown) echo yes ;;
    password) echo password ;;
    *) echo no ;;
  esac
}

entry() {
  case $mode in
    split | wide-own) echo "$rule_file" ;;
    wide-other) echo /etc/sudoers.d/10-pacman ;;
    *) echo /etc/sudoers ;;
  esac
}

case "${1:-}" in
  -u)
    # sudo -u ACCOUNT CMD...: as that account, which is this one here
    shift 2
    exec "$@"
    ;;
  -v)
    echo "ASK" >>"$log"
    [[ ${STUB_SUDO_REFUSE:-} == 1 ]] && { echo "sudo: 1 incorrect password attempt" >&2; exit 1; }
    : >"$given"
    exit 0
    ;;
  -n)
    if [[ ${2:-} == -k && ${3:-} == -ll ]]; then
      shift 3
      [[ ${1:-} == -- ]] && shift
      cmd="$*"
      case $mode in
        unlisted) echo "sudo: a password is required" >&2; exit 1 ;;
        odd) echo "sudo: unrecognized option '-ll'" >&2; exit 1 ;;
        unknown) printf 'User may run:\n    (root) NOPASSWD: %s\n' "$cmd"; exit 0 ;;
      esac
      a=$(allowed "$cmd")
      [[ $a == no ]] && exit 1
      printf 'User %s may run the following commands on stubhost:\n\nSudoers entry: %s\n' "$(id -un)" "$(entry)"
      printf '    RunAsUsers: root\n'
      [[ $a == yes ]] && printf '    Options: !authenticate\n'
      printf '    Commands:\n\t%s\n' "$cmd"
      exit 0
    fi
    # sudo -n true (the keepalive): no cached password here, so the loop ends at once
    exit 1
    ;;
esac

# Running a command as root: logged, never run
cmd="$*"
if [[ $(allowed "$cmd") != yes && ! -e $given ]]; then
  echo "IMPLICIT-ASK: $cmd" >>"$log"
fi
echo "ROOT: $cmd" >>"$log"
if [[ $cmd == *" -Syu --noconfirm" && -n ${STUB_QT_AFTER:-} ]]; then
  echo "$STUB_QT_AFTER" >"$STUB_STATE/qt"
fi
if [[ -n ${STUB_ROOT_FAIL:-} && $cmd == *"$STUB_ROOT_FAIL"* ]]; then
  exit 1
fi
exit 0

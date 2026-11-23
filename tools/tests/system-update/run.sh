#!/usr/bin/env bash
# Tests for scripts/caelestia4/system-update.sh (Nexus > Updates > Update everything): a copy of it runs in a temporary
# directory with stub sudo, pacman, yay, curl, makepkg, flock, script, df, notify-send and the rest on PATH, so nothing
# is installed, built or asked. The stub sudo (tools/tests/update-sudo/stubs/sudo.sh) logs what would run as root and
# answers with the rule tools/update-sudo-rule.sh writes (made here with C4_SUDOERS_DIR). Checked, per sudo state: the
# order of the steps (keyrings, repo upgrade, AUR, rebuild), and when the password is asked: with the split rule only
# right before an AUR step or a rebuild that has something to do, once; without a rule once at the start; refused,
# never again.
# Usage: tools/tests/system-update/run.sh
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fails=0
ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails + 1)); }

# The script and what it sources, at the same relative places; system.py is a stub giving the rebuild check
ii="$tmp/ii"
mkdir -p "$ii/scripts/caelestia4" "$ii/modules/caelestia/utils/scripts"
for f in system-update.sh tr.sh update-sudo-state.sh; do
  cp "$repo/dots/.config/quickshell/ii/scripts/caelestia4/$f" "$ii/scripts/caelestia4/"
done
script="$ii/scripts/caelestia4/system-update.sh"
cat >"$ii/modules/caelestia/utils/scripts/system.py" <<'PY'
import json, os, sys
if sys.argv[1:] == ["components"]:
    print(json.dumps({"repo": os.environ["STUB_REPO"],
                      "components": [{"name": "Quickshell", "needsRebuild": os.environ.get("STUB_REBUILD") == "1"},
                                     {"name": "Caelestia plugin", "needsRebuild": False}]}))
PY

# A clone with one package of ours to rebuild and the plugin's build script
fake_repo="$tmp/repo"
mkdir -p "$fake_repo/packaging/caelestia4-quickshell" "$fake_repo/tools"
cat >"$fake_repo/tools/build-caelestia-plugin.sh" <<'SH'
#!/usr/bin/env bash
echo "PLUGIN" >>"$STUB_LOG"
SH
chmod +x "$fake_repo/tools/build-caelestia-plugin.sh"

bin="$tmp/bin"
mkdir -p "$bin"
cp "$repo/tools/tests/update-sudo/stubs/sudo.sh" "$bin/sudo"
stub() { printf '#!/usr/bin/env bash\n%s\n' "$2" >"$bin/$1"; chmod +x "$bin/$1"; }
# pacman as the account: queries only (root's go through the stub sudo)
stub pacman '
case "$1" in
  -Q)
    if [[ $# -eq 1 ]]; then exit 0; fi
    case "$2" in
      qt6-base) echo "qt6-base $(cat "$STUB_STATE/qt")-1" ;;
      archlinux-keyring|caelestia4-quickshell) echo "$2 1-1" ;;
      *) exit 1 ;;
    esac ;;
  -Si) [[ $2 == archlinux-keyring ]] ;;
  -Qqm) printf "%s\n" some-aur-app caelestia4-quickshell ;;
  *) echo "pacman stub: unexpected $*" >&2; exit 1 ;;
esac'
# yay: -Qua lists what has an update; -Sua installs it through sudo pacman, as yay does
stub yay '
case "$1" in
  -Qua) [[ -z ${STUB_AUR_PENDING:-} ]] || echo "some-aur-app 1-1 -> 2-1"; echo "caelestia4-quickshell 1-1 -> 2-1" ;;
  -Sua) echo "YAY: $*" >>"$STUB_LOG"
        [[ -z ${STUB_AUR_PENDING:-} ]] || sudo /usr/bin/pacman -U --noconfirm /var/cache/yay/some-aur-app-2-1.pkg.tar.zst ;;
  *) echo "yay stub: unexpected $*" >&2; exit 1 ;;
esac'
stub makepkg '
case "$1" in
  -Cfs) echo "MAKEPKG: $PWD" >>"$STUB_LOG"; : >"$PWD/caelestia4-quickshell-1-1-x86_64.pkg.tar.zst" ;;
  --packagelist) echo "$PWD/caelestia4-quickshell-1-1-x86_64.pkg.tar.zst"; echo "$PWD/caelestia4-quickshell-debug-1-1-x86_64.pkg.tar.zst" ;;
esac'
stub curl 'exit 0'
stub flock '[[ $# -ge 3 ]] && exec "${@:3}"; exit 0'
# script -qefc CMD LOG: runs CMD (no log)
stub script 'while [[ $# -gt 0 && $1 != -*c* ]]; do shift; done; exec bash -c "$2"'
stub df 'printf "Avail\n%s\n" "${STUB_DF:-999999999999}"'
stub notify-send 'echo "NOTIFY: $*" >>"$STUB_LOG"'
stub systemd-inhibit 'exit 1'
stub pacdiff 'exit 0'
stub hyprctl 'echo "[]"'
stub pgrep 'exit 1'
stub systemctl 'echo "SYSTEMCTL: $*" >>"$STUB_LOG"'

export PATH="$bin:/usr/bin:/bin" STUB_LOG="$tmp/log" STUB_STATE="$tmp/state" STUB_REPO="$fake_repo"
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config" XDG_STATE_HOME="$tmp/home/.local/state" XDG_RUNTIME_DIR="$tmp/run"
export LC_ALL=C LANG=C
mkdir -p "$HOME" "$XDG_RUNTIME_DIR" "$STUB_STATE"
unset C4_UPDATE_LOGGED C4_UPDATE_AWAKE SUDO_USER

# The rule, as tools/update-sudo-rule.sh writes it (its own test checks it in detail)
export C4_SUDOERS_DIR="$tmp/sudoers.d"
mkdir -p "$C4_SUDOERS_DIR" "$tmp/idbin"
printf '#!/usr/bin/env bash\n[[ $1 == -u ]] && { echo 0; exit 0; }\nexec /usr/bin/id "$@"\n' >"$tmp/idbin/id"
printf '#!/usr/bin/env bash\nexit 0\n' >"$tmp/idbin/chown"
printf '#!/usr/bin/env bash\nexit 0\n' >"$tmp/idbin/visudo"
chmod +x "$tmp/idbin"/*
PATH="$tmp/idbin:$PATH" STUB_SUDO_MODE=split SUDO_USER=tester bash "$repo/tools/update-sudo-rule.sh" enable >/dev/null 2>&1 \
  || { echo "FAIL: couldn't make the rule"; echo "system-update tests: FAILED"; exit 1; }
[[ -f $C4_SUDOERS_DIR/zz-caelestia4-update ]] || { echo "FAIL: no rule"; echo "system-update tests: FAILED"; exit 1; }

# update NAME MODE [VAR=value...]: run the update; its log in $tmp/log, its exit code in $rc
update() {
  local name=$1 mode=$2
  shift 2
  : >"$STUB_LOG"
  rm -f "$STUB_STATE/password-given"
  echo "6.9" >"$STUB_STATE/qt"
  rc=0
  env STUB_SUDO_MODE="$mode" "$@" bash "$script" </dev/null >"$tmp/out.$name" 2>&1 || rc=$?
}
count() { grep -c -- "$1" "$STUB_LOG" || true; }
# line of the first log entry matching, 0 if none
at() { grep -n -m 1 -- "$1" "$STUB_LOG" | cut -d: -f1 || true; }
expect() { # NAME CONDITION...: the condition holds, else a failure with the log
  local name=$1
  shift
  if "$@"; then ok "$name"; else bad "$name"; sed 's/^/    /' "$STUB_LOG"; fi
}
before() { local a b; a=$(at "$1"); b=$(at "$2"); [[ -n $a && -n $b && $a -lt $b ]]; }
none() { [[ $(count "$1") -eq 0 ]]; }
once() { [[ $(count "$1") -eq 1 ]]; }
code() { [[ $rc -eq $1 ]]; }

# 1. split, nothing from the AUR, no rebuild: no password at all; keyrings, then the repo upgrade
update quiet split
expect "split, nothing to ask for: exit 0" code 0
expect "split, nothing to ask for: no password" none "ASK"
expect "split: keyrings before the repo upgrade" before "ROOT: .*-Sy --needed --noconfirm archlinux-keyring" "ROOT: .*-Syu --noconfirm"
expect "split: the repo upgrade before the AUR step" before "ROOT: .*-Syu --noconfirm" "YAY: -Sua"
expect "split: our own packages left to the rebuild" bash -c "grep -q 'YAY: -Sua .*--ignore caelestia4-quickshell' '$STUB_LOG'"
expect "split, nothing to ask for: no rebuild" none "MAKEPKG"

# 2. split, an AUR update: asked once, after the repo upgrade, right before the AUR step
update aur split STUB_AUR_PENDING=1
expect "split, AUR update: exit 0" code 0
expect "split, AUR update: asked once" once "^ASK"
expect "split, AUR update: asked after the repo upgrade" before "ROOT: .*-Syu --noconfirm" "^ASK"
expect "split, AUR update: asked before the AUR step" before "^ASK" "YAY: -Sua"
expect "split, AUR update: no prompt in the middle" none "IMPLICIT-ASK"

# 3. split, a rebuild only: asked once, after the AUR step, right before the build
update rebuild split STUB_REBUILD=1
expect "split, rebuild: exit 0" code 0
expect "split, rebuild: asked once" once "^ASK"
expect "split, rebuild: asked after the AUR step" before "YAY: -Sua" "^ASK"
expect "split, rebuild: asked before the build" before "^ASK" "MAKEPKG"
expect "split, rebuild: built, installed, then the plugin" before "MAKEPKG" "ROOT: .*pacman -U --noconfirm .*caelestia4-quickshell-1-1"
expect "split, rebuild: no debug package installed" none "debug"
expect "split, rebuild: the plugin built" once "PLUGIN"
expect "split, rebuild: no prompt in the middle" none "IMPLICIT-ASK"

# 4. split, a new Qt minor from the repo upgrade: rebuilds too
update qt split STUB_QT_AFTER=6.10
expect "split, new Qt: rebuilt" once "MAKEPKG"
expect "split, new Qt: asked once" once "^ASK"

# 5. split, AUR update and rebuild: asked once only, before the AUR step
update both split STUB_AUR_PENDING=1 STUB_REBUILD=1
expect "split, AUR and rebuild: exit 0" code 0
expect "split, AUR and rebuild: asked once" once "^ASK"
expect "split, AUR and rebuild: asked before the AUR step" before "^ASK" "YAY: -Sua"
expect "split, AUR and rebuild: rebuilt" once "MAKEPKG"
expect "split, AUR and rebuild: no prompt in the middle" none "IMPLICIT-ASK"

# 6. split, refused: asked once, the AUR and the rebuild of packages skipped, the plugin still built, a failure
update refused split STUB_AUR_PENDING=1 STUB_REBUILD=1 STUB_SUDO_REFUSE=1
expect "split, refused: exit 1" code 1
expect "split, refused: asked once" once "^ASK"
expect "split, refused: the repo upgrade still ran" once "ROOT: .*-Syu --noconfirm"
expect "split, refused: no AUR step" none "YAY: -Sua"
expect "split, refused: no package rebuilt" none "MAKEPKG"
expect "split, refused: the plugin still built" once "PLUGIN"
expect "split, refused: no prompt in the middle" none "IMPLICIT-ASK"
expect "split, refused: a critical notification" bash -c "grep -q 'NOTIFY: .*-u critical' '$STUB_LOG'"

# 7. no rule: asked once, before anything runs as root
update off off STUB_AUR_PENDING=1 STUB_REBUILD=1
expect "no rule: exit 0" code 0
expect "no rule: asked once" once "^ASK"
expect "no rule: asked first" bash -c "[[ \$(head -n 1 '$STUB_LOG') == ASK ]]"
expect "no rule: everything ran" bash -c "grep -q 'YAY: -Sua' '$STUB_LOG' && grep -q MAKEPKG '$STUB_LOG'"

# 8. no rule, refused: asked once, nothing run as root, a failure
update off-refused off STUB_AUR_PENDING=1 STUB_SUDO_REFUSE=1
expect "no rule, refused: exit 1" code 1
expect "no rule, refused: asked once" once "^ASK"
expect "no rule, refused: nothing run as root" none "ROOT:"
expect "no rule, refused: no AUR step" none "YAY:"

# 9. sudo lists nothing without a password (listpw), or can't be read: as no rule
update unlisted unlisted STUB_AUR_PENDING=1
expect "unlisted: asked once, first" bash -c "[[ \$(grep -c '^ASK' '$STUB_LOG') -eq 1 && \$(head -n 1 '$STUB_LOG') == ASK ]]"
update unknown odd
expect "unknown: asked once, first" bash -c "[[ \$(grep -c '^ASK' '$STUB_LOG') -eq 1 && \$(head -n 1 '$STUB_LOG') == ASK ]]"

# 10. the older pacman-wide rule: never asked
update wide wide-own STUB_AUR_PENDING=1 STUB_REBUILD=1
expect "wide: exit 0" code 0
expect "wide: never asked" none "ASK"
expect "wide: everything ran" bash -c "grep -q 'YAY: -Sua' '$STUB_LOG' && grep -q MAKEPKG '$STUB_LOG'"

# 11. the repo upgrade fails: stops there, nothing from the AUR
update failed split STUB_AUR_PENDING=1 STUB_ROOT_FAIL="-Syu --noconfirm"
expect "repo upgrade failed: exit 1" code 1
expect "repo upgrade failed: no AUR step" none "YAY:"
expect "repo upgrade failed: no password asked" none "ASK"

# 12. too little free space: stops before sudo
update full split STUB_DF=1024
expect "no free space: exit 1" code 1
expect "no free space: nothing run" none "ROOT:"

if ((fails)); then
  echo "system-update tests: $fails FAILED"
  exit 1
fi
echo "system-update tests: OK"

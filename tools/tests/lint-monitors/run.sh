#!/usr/bin/env bash
# Tests for tools/lint-monitors.sh: copies it into throwaway git repos under a temporary directory, adds probe files
# that it must flag and ones it must leave alone, and checks what it reports. Touches nothing outside that directory.
# The probe values are put together from pieces at run time, so this file itself has nothing for the lint to find.
# Usage: tools/tests/lint-monitors/run.sh
set -uo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
lint="$here/../../lint-monitors.sh"
tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CEILING_DIRECTORIES=$tmp

fails=0
ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails + 1)); }

# Pieces of the probe values
d='-' n=1 w=2560 h=1440 r=60 x=x frac=1.75

# repo DIR: a git repo holding a copy of the lint
repo() {
  mkdir -p "$1/tools" && cp "$lint" "$1/tools/" && git -C "$1" init -q
}
# probe DIR FILE TEXT: write a probe file and track it
probe() {
  mkdir -p "$(dirname "$1/$2")" && printf '%s\n' "$3" >"$1/$2" && git -C "$1" add -- "$2"
}

must_flag=(
  "a.qml|name: \"eDP${d}${n}\""
  "b.qml|screens: [\"HDMI${d}A${d}${n}\"]"
  "c.md|xrandr --output HDMI${d}${n} --auto"
  "d.md|xrandr --output HDMI${n} --off"
  "e.md|eDP${n} is the laptop panel"
  "f.md|DPI${d}${n}"
  "g.md|DisplayPort${d}0"
  "h.md|Writeback${d}${n}"
  "i.md|monitor desc"":Some Maker 27"
  "j.md|${w}${x}${h}@${r}"
  "k.lua|hl.monitor({ output = \"NAME\", mode = \"preferred\" })"
  "l.lua|hl.monitor({ output = \"\", mode = \"${w}${x}${h}\" })"
  "m.lua|hl.monitor({ output = \"\", scale = ${frac} })"
  "n.conf|monitor=NAME,preferred,auto,1"
  "o.conf|monitor=,${w}${x}${h},auto,1"
  "p.conf|monitor=,preferred,auto,${frac}"
  "q.conf|  output = NAME"
  "r.conf|  mode = ${w}${x}${h}"
  "k2.lua|hl.monitor({ output = 'NAME' })"
  "l2.lua|hl.monitor({ output = '', mode = '${w}${x}${h}' })"
  "m2.lua|hl.monitor({ output = '', scale = '${frac}' })"
  "c2.md|xrandr --output DP${n} --auto"
  "c3.md|eDP${d}${n}."
  "third_party/caelestia-shell/README.md|Plug the cable into DP${d}${n} first."
)
must_pass=(
  "s.conf|monitor ="
  "t.conf|monitor=,preferred,auto,1"
  "u.lua|local output = \"none\""
  "v.lua|hl.monitor({ output = \"\", mode = \"preferred\", scale = 1.0 })"
  "w.txt|/usr/share/icons/hicolor/128${x}128@2/apps/x.png"
  "y.md|USB${d}C dock, DPMS off, 1080p, the HDMI port"
  "y2.md|Needs HDMI2.1 and DP1.4, a USB3 or USB4 port, or VGA${n} on old cards"
  "z.conf|monitor = \$main, preferred, auto, 1"
  "z2.conf|  output = \$main"
  "z3.lua|local output = 'none'"
  "third_party/caelestia-shell/README.md|For example, to hide the bar on the monitor named \`DP${d}${n}\`:"
  "third_party/caelestia-shell/README2.md|**\`~/.config/caelestia/monitors/DP${d}${n}/shell.json\`**"
)

# 1. every must_flag probe is reported, no must_pass probe is, and the lint fails
repo "$tmp/all"
readme=''
for p in "${must_flag[@]}" "${must_pass[@]}"; do
  f=${p%%|*} t=${p#*|}
  # both README probes go into the one README, as they would upstream
  if [[ $f == third_party/caelestia-shell/README*.md ]]; then readme+="$t"$'\n'; continue; fi
  probe "$tmp/all" "$f" "$t"
done
probe "$tmp/all" third_party/caelestia-shell/README.md "${readme%$'\n'}"
out=$("$tmp/all/tools/lint-monitors.sh"); rc=$?
[[ $rc -eq 1 ]] && ok "fails on monitor data" || bad "exit $rc on monitor data, want 1"
for p in "${must_flag[@]}"; do
  f=${p%%|*} t=${p#*|}
  grep -F -- ": $f:" <<<"$out" | grep -qF -- "$t" && ok "flags $f" || bad "missed $f: $t"
done
for p in "${must_pass[@]}"; do
  f=${p%%|*} t=${p#*|}
  [[ $f == third_party/caelestia-shell/README*.md ]] && f=third_party/caelestia-shell/README.md
  grep -F -- ": $f:" <<<"$out" | grep -qF -- "$t" && bad "false positive in $f: $t" || ok "leaves alone $f"
done

# 2. a tree with only the allowed lines passes
repo "$tmp/clean"
for p in "${must_pass[@]}"; do
  f=${p%%|*} t=${p#*|}
  [[ $f == third_party/caelestia-shell/README*.md ]] && f=third_party/caelestia-shell/README.md
  mkdir -p "$(dirname "$tmp/clean/$f")" && printf '%s\n' "$t" >>"$tmp/clean/$f"
  git -C "$tmp/clean" add -- "$f"
done
out=$("$tmp/clean/tools/lint-monitors.sh"); rc=$?
[[ $rc -eq 0 && $out == "no monitor data" ]] && ok "passes a clean tree" || bad "clean tree: exit $rc: $out"

# 3. when git grep can't run (no repo), the lint fails instead of reporting clean
mkdir -p "$tmp/norepo/tools" && cp "$lint" "$tmp/norepo/tools/"
out=$("$tmp/norepo/tools/lint-monitors.sh" 2>/dev/null); rc=$?
[[ $rc -ne 0 ]] && grep -q 'git grep failed' <<<"$out" && ok "fails when git grep fails" \
  || bad "no repo: exit $rc: $out"

[[ $fails -eq 0 ]] && echo "lint-monitors tests: OK" || echo "lint-monitors tests: $fails FAILED"
exit $((fails > 0))

#!/usr/bin/env bash
# No monitor data in the repo (run by tools/ci-lint.sh; tests in tools/tests/lint-monitors/run.sh). A screen's
# connector name, description, mode and scale are read at run time (hyprctl monitors, Quickshell.screens), never
# written into config, code, comments or docs, so the repo works on any screen and says nothing about the one it was
# written on. Fails on:
#   1. a connector name: eDP, DP, DPI, DisplayPort, HDMI (with or without the A-D letter), DVI, VGA, LVDS, DSI,
#      Virtual, HEADLESS, Writeback, USB or Unknown, a dash, then a number. Without the dash (how xrandr names them)
#      only eDP and HDMI then a number count, or any of the names right after --output, since the dashless DP, USB
#      and VGA forms are also how port versions and specs are written. A number followed by a dot and a digit is a
#      version (HDMI 2.1 written without the space), not a name
#   2. a Hyprland monitor description (desc:...)
#   3. a mode with a refresh rate (WIDTHxHEIGHT@RATE, the rate two digits or more, so hicolor's 128x128@2 icon
#      folders don't count)
#   4. in a .lua file: any non-local output = "..." or monitor = "..." string (Hyprland's monitor and workspace
#      rules name a screen this way; a local variable with that name is left alone), a mode = "WIDTHxHEIGHT", or a
#      fractional scale, with double or single quotes
#   5. in a .conf file: a monitor = line with a name, a WIDTHxHEIGHT mode or a fractional scale (hyprlock's empty
#      "monitor =" means every screen and is fine), and a monitorv2 block's output = name or mode = WIDTHxHEIGHT. A
#      $variable in place of the name is fine: it keeps the name in a sourced file outside the repo
# The patterns are generic: none of them names a real screen. A check that can't run (git grep fails) fails too.
# Checked: every text file git tracks, Caelestia's vendored shell (third_party/caelestia-shell) included, since this
# fork patches its QML too. One allowed exception, matched by its text and not by line number:
#   - third_party/caelestia-shell/README.md, the per-monitor example ("the monitor named ..." and its
#     caelestia/monitors/<name>/shell.json path): Caelestia's own docs, kept as upstream wrote them so that
#     tools/sync-upstreams.sh applies cleanly, and the name there is a placeholder, not a screen of this machine.
#     The rest of that README is still checked.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2

fail=0
allow='^third_party/caelestia-shell/README\.md:[0-9]+:.*(the monitor named |caelestia/monitors/[^/[:space:]]+/shell\.json)'
# check REASON PATTERN EXCLUDE PATHSPEC...: report each tracked line matching the extended regex PATTERN, except the
# ones matching EXCLUDE (an extended regex on the path:line:text output, or empty) or the allowed exception above
check() {
  local reason=$1 pattern=$2 exclude=$3; shift 3
  local hits rc
  hits=$(git grep -nIE -e "$pattern" -- "$@")
  rc=$?
  [[ $rc -eq 1 ]] && return 0
  if [[ $rc -ne 0 ]]; then echo "LINT: git grep failed ($rc) for $reason"; fail=1; return; fi
  hits=$(grep -vE -e "$allow" ${exclude:+-e "$exclude"} <<<"$hits")
  [[ -z $hits ]] && return 0
  while IFS= read -r line; do echo "LINT: $reason: $line"; done <<<"$hits"
  fail=1
}
B='(^|[^[:alnum:]_])' # start of a word
S='[[:space:]]*'
FRAC='[0-9]*\.[0-9]*[1-9]' # a number with a non-zero fraction: 1.25, 1.75 (1.0 is fine)
CONN='(e?DP|DPI|DisplayPort|HDMI(-[A-D])?|DVI(-[ADI])?|VGA|LVDS|DSI|Virtual|HEADLESS|Writeback|USB|Unknown)'
NV='($|[^[:alnum:]_.]|\.($|[^0-9]))' # end of a word that isn't a version number (2.1)
check "connector name" \
  "${B}(${CONN}-[0-9]+|(eDP|HDMI)[0-9]+|--output[[:space:]]+${CONN}[0-9]+)${NV}" '' .
check "monitor description" "${B}desc:[[:alnum:]]" '' .
check "mode with a refresh rate" "${B}[0-9]{3,5}x[0-9]{3,5}@[0-9]{2}" '' .
check "output or monitor string in Lua" "${B}(output|monitor)${S}=${S}[\"'][^\"']" "^[^:]+:[0-9]+:${S}local[[:space:]]" '*.lua'
check "fixed mode in Lua" "${B}mode${S}=${S}[\"'][0-9]+x[0-9]+" '' '*.lua'
check "fractional scale in Lua" "${B}scale${S}=${S}[\"']?${FRAC}" '' '*.lua'
check "monitor = line with a name, mode or fractional scale" \
  "^${S}monitor${S}=${S}([^\$,#[:space:]]|[^,]*,${S}[0-9]+x[0-9]+|[^,]*,[^,]*,[^,]*,${S}${FRAC})" '' '*.conf'
check "monitorv2 output or mode" "^${S}(output${S}=${S}[^\$#[:space:]]|mode${S}=${S}[0-9]+x[0-9]+)" '' '*.conf'

[[ $fail -eq 0 ]] && echo "no monitor data"
exit $fail

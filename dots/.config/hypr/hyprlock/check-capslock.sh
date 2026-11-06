#!/bin/env bash

MAIN_KB_CAPS=$(hyprctl devices | grep -B 6 "main: yes" | grep "capsLock" | head -1 | awk '{print $2}')

if [ "$MAIN_KB_CAPS" = "yes" ]; then
    source "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/scripts/caelestia4/tr.sh" 2>/dev/null || tr_() { printf '%s' "$1"; }
    tr_ "Caps Lock is on"; echo
else
    echo ""
fi

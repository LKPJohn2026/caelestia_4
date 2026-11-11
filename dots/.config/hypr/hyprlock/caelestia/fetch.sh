#!/usr/bin/env bash
# caelestia4 hyprlock: system card (like Caelestia's lock "Fetch")
source "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/scripts/caelestia4/tr.sh" 2>/dev/null || { tr_() { printf '%s' "$1"; }; tr_pad() { printf '%s  ' "$1"; }; }
. /etc/os-release
row() { printf '<span alpha="70%%">%s</span>%s\n' "$(tr_pad "$1" 9)" "$2"; }
s=$(awk '{ print int($1) }' /proc/uptime)
d=$((s / 86400)) h=$((s % 86400 / 3600)) m=$((s % 3600 / 60))
up="$(tr_ "%1 min" "$m")"
((h)) && up="$(tr_ "%1 h" "$h") $up"
((d)) && up="$(tr_ "%1 d" "$d") $up"
printf '<b>%s@%s</b>\n' "$USER" "${HOSTNAME:-$(cat /proc/sys/kernel/hostname)}" # hostname(1) is in inetutils, not always installed
row "$(tr_ "OS")" "$PRETTY_NAME"
row "$(tr_ "Kernel")" "$(uname -r)"
printf '<span alpha="70%%">WM</span>      Hyprland\n'
row "$(tr_ "Uptime")" "$up"
